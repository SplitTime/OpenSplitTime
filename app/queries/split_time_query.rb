# frozen_string_literal: true

class SplitTimeQuery < BaseQuery

  def self.typical_segment_time(segment, effort_ids)
    # Params should all be integers, but convert them to integers
    # to protect against SQL injection

    begin_lap = segment.begin_lap.to_i
    begin_id = segment.begin_id.to_i
    begin_bitkey = segment.begin_bitkey.to_i
    end_lap = segment.end_lap.to_i
    end_id = segment.end_id.to_i
    end_bitkey = segment.end_bitkey.to_i

    query = <<-SQL
      SELECT AVG(extract(epoch from(st2.absolute_time - st1.absolute_time))) AS segment_time,
             COUNT(st1.absolute_time) AS effort_count
      FROM (SELECT st.effort_id, st.absolute_time
           FROM split_times st 
           WHERE st.lap = #{begin_lap} 
             AND st.split_id = #{begin_id} 
             AND st.sub_split_bitkey = #{begin_bitkey}
             AND (st.data_status IN (#{valid_statuses_list}) OR st.data_status IS NULL))
           AS st1,
           (SELECT st.effort_id, st.absolute_time
           FROM split_times st 
           WHERE st.lap = #{end_lap} 
             AND st.split_id = #{end_id} 
             AND st.sub_split_bitkey = #{end_bitkey}
             AND (st.data_status IN (#{valid_statuses_list}) OR st.data_status IS NULL))
           AS st2
      WHERE st1.effort_id = st2.effort_id
    SQL

    query += " AND st1.effort_id IN (#{sql_safe_integer_list(effort_ids)})" if effort_ids
    SplitTime.connection.execute(query.squish).values.flatten.map(&:to_i)
  end

  def self.with_time_point_rank
    query = <<-SQL
      with
        existing_scope as (#{existing_scope_sql}),

        split_times_scoped as 
          (select split_times.*
           from split_times
           inner join existing_scope on existing_scope.id = split_times.id),

        start_split_times as
          (select split_times.id, effort_id, absolute_time
           from split_times
           inner join splits on splits.id = split_times.split_id
           where lap = 1 and kind = 0 and effort_id in (select effort_id from split_times_scoped)
           order by effort_id),

        main_subquery as
          (select split_times_scoped.effort_id, lap, split_id, sub_split_bitkey,
            extract(epoch from (split_times_scoped.absolute_time - sst.absolute_time)) as seconds_from_start,
            split_times_scoped.absolute_time, 
            efforts.gender as effort_gender, 
            efforts.age as effort_age, 
            efforts.id as tiebreaker_id, 
            events.home_time_zone as event_home_zone
          from split_times_scoped
          inner join efforts on efforts.id = split_times_scoped.effort_id
          inner join events on events.id = efforts.event_id
          left join start_split_times sst on sst.effort_id = split_times_scoped.effort_id 
          where sst.id != split_times_scoped.id)

      select *, 
            rank() over 
                (partition by lap, 
                              split_id, 
                              sub_split_bitkey 
                order by seconds_from_start, 
                         effort_gender desc, 
                         effort_age desc,
                         tiebreaker_id) 
            as time_point_rank,
            absolute_time,
            event_home_zone
      from main_subquery 
      order by time_point_rank
    SQL
    query.squish
  end

  def self.time_detail(args)
    scope = where_string_from_hash(args[:scope])
    home_time_zone = args[:home_time_zone]
    time_zone = ActiveSupport::TimeZone.find_tzinfo(home_time_zone).identifier

    query = <<~SQL
      set timezone='#{time_zone}';

      with start_split_times as
        (select effort_id, absolute_time
         from split_times
         inner join splits on splits.id = split_times.split_id
         where lap = 1 and kind = 0 and effort_id in (select id from efforts where #{scope})
         order by effort_id)
     
      select st.id,
             st.effort_id,
             st.lap,
             st.split_id,
             st.sub_split_bitkey as bitkey,
             st.stopped_here,
             st.pacer,
             st.data_status as data_status_numeric,
             st.absolute_time as absolute_time_string,
             trim(both '"' from to_json(st.absolute_time at time zone 'UTC')::text) as day_and_time_string,
             extract(epoch from (st.absolute_time - sst.absolute_time)) as time_from_start,
             case 
               when st.effort_id = lag(st.effort_id) over (order by st.effort_id, st.lap, distance_from_start, st.sub_split_bitkey) 
               then extract(epoch from(st.absolute_time - lag(st.absolute_time) 
                      over (order by st.effort_id, st.lap, distance_from_start, st.sub_split_bitkey))) 
               else null 
             end as segment_time
      from split_times st
      inner join splits on splits.id = st.split_id
      inner join efforts on efforts.id = st.effort_id
      left join start_split_times sst on sst.effort_id = st.effort_id
      where #{scope}
    SQL
    query.squish
  end

  def self.effort_times(args)
    lap, split_id, bitkey = args[:time_point].values
    lowest_time, highest_time = args[:time_range].begin, args[:time_range].end
    finished_only = !!args[:finished_only]
    limit = args[:limit]

    query = <<~SQL
      with
        split_times_scoped as
          (select * 
           from split_times
           inner join efforts on efforts.id = split_times.effort_id
           inner join events on events.id = efforts.event_id
           inner join event_groups on event_groups.id = events.event_group_id
           where lap = #{lap} and split_id = #{split_id} and sub_split_bitkey = #{bitkey} 
             and event_groups.concealed = 'f'
             and (split_times.data_status in (2, 3) or split_times.data_status is null)),

        starting_split_times as
          (select effort_id, absolute_time
           from split_times
           inner join splits on splits.id = split_times.split_id
           where lap = 1 and kind = 0 and effort_id in (select effort_id from split_times_scoped)
           order by effort_id),

        finished_effort_ids as
          (select effort_id
           from split_times
           inner join splits on splits.id = split_times.split_id
           where lap = #{lap} and kind = 1 and effort_id in (select effort_id from split_times_scoped)
           order by effort_id),

        main_subquery as
          (select st.effort_id, 
                  extract(epoch from(st.absolute_time - sst.absolute_time)) as time_from_start, 
                  sst.absolute_time as start_time,
                  fe.effort_id is not null as finished
           from split_times_scoped st
             inner join starting_split_times sst on sst.effort_id = st.effort_id
             left join finished_effort_ids fe on fe.effort_id = st.effort_id
           order by st.effort_id)

      select effort_id, time_from_start
      from main_subquery
        where time_from_start between #{lowest_time} and #{highest_time}
        and (#{finished_only} = false or finished)
      order by start_time desc
      limit #{limit}
    SQL
    query.squish
  end

  def self.split_traffic(args)
    event_group = args[:event_group]
    parameterized_split_name = args[:split_name].parameterize
    band_width = args[:band_width] / 1.second
    home_time_zone = event_group.home_time_zone
    time_zone = ActiveSupport::TimeZone.find_tzinfo(home_time_zone).identifier

    query = <<~SQL
      set timezone='#{time_zone}';

      with 
        scoped_split_times as
          (select st.effort_id, st.sub_split_bitkey, st.lap, st.absolute_time at time zone 'UTC' as day_and_time
           from split_times st
             inner join efforts ef on ef.id = st.effort_id
             inner join events ev on ev.id = ef.event_id
             inner join splits s on s.id = st.split_id
           where event_group_id = #{event_group.id} and s.parameterized_base_name = '#{parameterized_split_name}'
           order by absolute_time),

        finish_split_times as
          (select effort_id, lap
           from efforts ef
             inner join split_times st on st.effort_id = ef.id
             inner join splits s on s.id = st.split_id
           where ef.id in (select effort_id from scoped_split_times) and s.kind = 1
           order by ef.id),
           
        interval_starts as
          (select *
           from generate_series((select min(to_timestamp(floor((extract(epoch from day_and_time)) / #{band_width}) * #{band_width})) from scoped_split_times), 
                                (select max(to_timestamp(floor((extract(epoch from day_and_time)) / #{band_width}) * #{band_width})) + interval '#{band_width} seconds' from scoped_split_times), 
                                 interval '#{band_width} seconds') time),
           
        intervals as
          (select time as start_time, lead(time) over(order by time) as end_time 
           from interval_starts)
           
      select to_char(i.start_time, 'Dy HH24:MI') as start_time, 
             to_char(i.end_time, 'Dy HH24:MI') as end_time, 
             count(case when st.sub_split_bitkey = 1 then 1 else null end) as in_count, 
             count(case when st.sub_split_bitkey = 64 then 1 else null end) as out_count,
             count(case when st.sub_split_bitkey = 1 and fst.effort_id is not null then 1 else null end) as finished_in_count,
             count(case when st.sub_split_bitkey = 64 and fst.effort_id is not null then 1 else null end) as finished_out_count
      from scoped_split_times st
        left join finish_split_times fst
          on fst.effort_id = st.effort_id and fst.lap = st.lap
        right join intervals i
          on st.day_and_time >= i.start_time and st.day_and_time < i.end_time
      where i.end_time is not null
      group by i.start_time, i.end_time
      order by i.start_time
    SQL
    query.squish
  end

  def self.starting_split_times(args)
    scope = where_string_from_hash(args[:scope])

    query = <<~SQL
      left join (select effort_id, absolute_time
                 from split_times
                   inner join splits on splits.id = split_times.split_id
                 where lap = 1 and kind = 0 and effort_id in (select id from efforts where #{scope})) sst
                 on sst.effort_id = split_times.effort_id
    SQL
    query.squish
  end

  def self.existing_scope_sql
    # have to do this to get the binds interpolated. remove any ordering and just grab the ID
    SplitTime.connection.unprepared_statement { SplitTime.reorder(nil).select("id").to_sql }
  end

  def self.valid_statuses_list
    sql_safe_integer_list(SplitTime.valid_statuses)
  end
end
