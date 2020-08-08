# frozen_string_literal: true

class EffortQuery < BaseQuery
  def self.rank_and_status(args = {})
    select_sql = sql_select_from_string(args[:fields], permitted_column_names, '*')
    order_sql = sql_order_from_hash(args[:sort], permitted_column_names, 'event_id,overall_rank')
    where_clause = args[:effort_id].present? ? "where id = #{args[:effort_id]}" : ''

    <<-SQL.squish
      with existing_scope as
               (#{existing_scope_sql}),

           efforts_scoped as
               (select efforts.*
                from efforts
                         inner join existing_scope on existing_scope.id = efforts.id),

           start_split_times as
               (select effort_id, absolute_time
                from split_times
                         inner join splits on splits.id = split_times.split_id
                where lap = 1
                  and kind = 0
                  and effort_id in (select id from efforts_scoped)
                order by effort_id),

           stopped_split_times as
               (select split_times.id               as stopped_split_time_id,
                       split_times.lap              as stopped_lap,
                       split_times.split_id         as stopped_split_id,
                       split_times.sub_split_bitkey as stopped_bitkey,
                       split_times.absolute_time    as stopped_absolute_time,
                       split_times.effort_id
                from split_times
                where effort_id in (select id from efforts_scoped)
                  and stopped_here = true),

           course_subquery as
               (select courses.id                  as course_id,
                       splits.distance_from_start  as course_distance,
                       splits.vert_gain_from_start as course_vert_gain
                from courses
                         inner join splits on splits.course_id = courses.id
                where splits.kind = 1),

           base_subquery as
               (select distinct on (efforts_scoped.id) 
                           efforts_scoped.*,
                           events.laps_required,
                           events.start_time                                           as event_start_time,
                           event_groups.home_time_zone,
                           splits.base_name                                            as final_split_name,
                           splits.distance_from_start                                  as final_lap_distance,
                           splits.vert_gain_from_start                                 as final_lap_vert_gain,
                           split_times.lap                                             as final_lap,
                           split_times.split_id                                        as final_split_id,
                           split_times.sub_split_bitkey                                as final_bitkey,
                           split_times.absolute_time                                   as final_absolute_time,
                           sst.absolute_time                                           as actual_start_time,
                           extract(epoch from (sst.absolute_time - events.start_time)) as start_offset,
                           split_times.elapsed_seconds                                 as final_elapsed_seconds,
                           split_times.id                                              as final_split_time_id,
                           stopped_split_time_id,
                           stopped_lap,
                           stopped_split_id,
                           stopped_bitkey,
                           stopped_absolute_time,
                           course_distance,
                           course_vert_gain,
                           case when splits.kind = 1 then true else false end          as final_lap_complete,
                           case
                               when split_times.lap > 1 or splits.kind in (1, 2) then true
                               else false end                                          as beyond_start
                from efforts_scoped
                         left join split_times on split_times.effort_id = efforts_scoped.id
                         left join splits on splits.id = split_times.split_id
                         left join events on events.id = efforts_scoped.event_id
                         inner join event_groups on event_groups.id = events.event_group_id
                         left join course_subquery on events.course_id = course_subquery.course_id
                         left join stopped_split_times stop_st on split_times.effort_id = stop_st.effort_id
                         left join start_split_times sst on split_times.effort_id = sst.effort_id
                order by efforts_scoped.id,
                         final_lap desc,
                         final_lap_distance desc,
                         final_bitkey desc),

           distance_subquery as
               (select *,
                       coalesce(scheduled_start_time, event_start_time)                           as assumed_start_time,
                       case when final_lap is null then false else true end                       as started,
                       final_lap                                                                  as laps_started,
                       case when final_lap_complete is true then final_lap else final_lap - 1 end as laps_finished,
                       (final_lap - 1) * course_distance + final_lap_distance                     as final_distance,
                       (final_lap - 1) * course_vert_gain + final_lap_vert_gain                   as final_vert_gain
                from base_subquery),

           finished_subquery as
               (select *,
                       case
                           when laps_required = 0 then
                               case when stopped_split_time_id is null then false else true end
                           else
                               case when laps_finished >= laps_required then true else false end
                           end
                           as finished,
                       case
                           when checked_in and actual_start_time is null and (assumed_start_time < current_timestamp)
                               then true
                           else false
                           end
                           as ready_to_start
                from distance_subquery),

           stopped_subquery as
               (select *,
                       case when finished or stopped_split_time_id is not null then true else false end as stopped
                from finished_subquery),

           main_subquery as
               (select *,
                       case when stopped and not finished then true else false end as dropped
                from stopped_subquery),

           ranking_subquery as
               (select #{select_sql},
                       case
                           when started then
                                       rank() over
                                   (partition by event_id
                                   order by started desc,
                                       dropped,
                                       final_lap desc nulls last,
                                       final_lap_distance desc,
                                       final_bitkey desc,
                                       final_elapsed_seconds,
                                       gender desc,
                                       age desc)
                           else null end
                           as overall_rank,
                       case
                           when started then
                                       rank() over
                                   (partition by event_id, gender
                                   order by started desc,
                                       dropped,
                                       final_lap desc nulls last,
                                       final_lap_distance desc,
                                       final_bitkey desc,
                                       final_elapsed_seconds,
                                       gender desc,
                                       age desc)
                           else null end
                           as gender_rank,
                       lag(id) over
                           (partition by event_id
                           order by started desc,
                               dropped,
                               final_lap desc nulls last,
                               final_lap_distance desc,
                               final_bitkey desc,
                               final_elapsed_seconds,
                               gender desc,
                               age desc)
                           as prior_effort_id,
                       lead(id) over
                           (partition by event_id
                           order by started desc,
                               dropped,
                               final_lap desc nulls last,
                               final_lap_distance desc,
                               final_bitkey desc,
                               final_elapsed_seconds,
                               gender desc,
                               age desc)
                           as next_effort_id
                from main_subquery)

      select *
      from ranking_subquery
      #{where_clause}
      order by #{order_sql}
    SQL
  end

  def self.over_segment_subquery(segment, existing_scope)
    segment_start_id = segment.begin_id
    segment_start_bitkey = segment.begin_bitkey
    segment_end_id = segment.end_id
    segment_end_bitkey = segment.end_bitkey
    existing_scope_subquery = sql_for_existing_scope(existing_scope)

    <<-SQL.squish
      (with

      existing_scope as (#{existing_scope_subquery}),

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

  def self.shift_event_scheduled_times(event, shift_seconds, current_user)
    <<-SQL.squish
        with time_subquery as
           (select ef.id, ef.scheduled_start_time + (#{shift_seconds} * interval '1 second') as computed_time
            from efforts ef
            where ef.event_id = #{event.id})
        
        update efforts
        set scheduled_start_time = computed_time,
            updated_at = current_timestamp,
            updated_by = #{current_user.id}
        from time_subquery
        where efforts.id = time_subquery.id
    SQL
  end

  def self.existing_scope_sql
    # have to do this to get the binds interpolated. remove any ordering and just grab the ID
    Effort.connection.unprepared_statement { Effort.reorder(nil).select('id').to_sql }
  end

  def self.sql_for_existing_scope(scope)
    scope.connection.unprepared_statement { scope.reorder(nil).select('id').to_sql }
  end

  def self.permitted_column_names
    EffortParameters.enriched_query
  end
end
