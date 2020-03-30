# frozen_string_literal: true

module Query
  class EffortOverSegment < ::Query::Base
    def self.sql(segment, existing_scope)
      segment_start_id = segment.begin_id
      segment_start_bitkey = segment.begin_bitkey
      segment_end_id = segment.end_id
      segment_end_bitkey = segment.end_bitkey

      <<-SQL.squish
      (with

      existing_scope as (#{sql_for_existing_scope(existing_scope)}),

      effort_start_time as (
          select effort_id, absolute_time
          from split_times
          inner join splits on splits.id = split_times.split_id
          where lap = 1 and kind = #{Split.kinds[:start]}
          order by effort_id
      ),

      effort_stopped as (
          select effort_id
          from split_times
          where stopped_here = true
      ),

      effort_laps_finished as (
          select st.effort_id, max(st.lap) as laps_finished
          from split_times st
          left join splits s on s.id = st.split_id
          where s.kind = #{Split.kinds[:finish]}
          group by st.effort_id
      ),

      segment_start as (
          select
              efforts.*,
              events.start_time as event_start_time,
              event_groups.home_time_zone,
              split_times.effort_id,
              split_times.absolute_time as segment_start_time,
              split_times.lap,
              split_times.split_id,
              split_times.sub_split_bitkey,
              events.laps_required
          from efforts
          inner join split_times on split_times.effort_id = efforts.id
          inner join events on events.id = efforts.event_id
          inner join event_groups on event_groups.id = events.event_group_id
          where split_times.split_id = #{segment_start_id} and split_times.sub_split_bitkey = #{segment_start_bitkey}
      ),

      segment_end as (
          select effort_id, lap, absolute_time as segment_end_time
          from split_times
          where split_times.split_id = #{segment_end_id} and split_times.sub_split_bitkey = #{segment_end_bitkey}
      )

      select
          ss.id,
          ss.event_id,
          ss.first_name,
          ss.last_name,
          ss.gender,
          ss.birthdate,
          ss.age,
          ss.city,
          ss.state_code,
          ss.country_code,
          ss.slug,
          ss.event_start_time,
          ss.home_time_zone,
          ss.effort_id,
          ss.segment_start_time as absolute_time_begin,
          ss.lap,
          ss.split_id,
          ss.sub_split_bitkey,
          ss.laps_required,
          ss.segment_start_time,
          extract(epoch from (segment_end_time - segment_start_time)) as segment_seconds,
          to_char(
              (extract(epoch from (segment_end_time - segment_start_time)) || ' second')::interval,
              'HH24:MI:SS'
          ) as segment_duration,
          rank() over (
              order by segment_end_time - segment_start_time, gender, -age, ss.lap
          ) as overall_rank,
          rank() over (
              partition by gender
              order by segment_end_time - segment_start_time, -age, ss.lap
          ) as gender_rank,
          (
              laps_required = 0
                  and ss.effort_id in (select effort_id from effort_stopped)
          ) or (
              laps_required > 0 and coalesce(laps_finished, 0) >= laps_required
          ) as finished,
          est.absolute_time as actual_start_time
      from segment_start ss
      inner join segment_end se on se.effort_id = ss.effort_id and se.lap = ss.lap
      left join effort_start_time est on est.effort_id = ss.effort_id
      left join effort_laps_finished elf on elf.effort_id = ss.effort_id
      where segment_end_time - segment_start_time > interval '0'
          and ss.id in (select id from existing_scope)
      order by overall_rank)

      as efforts
      SQL
    end
  end
end