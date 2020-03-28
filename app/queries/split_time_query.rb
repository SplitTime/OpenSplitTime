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
    focus_clause = effort_ids.present? ? "st1.effort_id IN (#{sql_safe_integer_list(effort_ids)})" : 'true'

    query = <<-SQL
      with segment_times as
           (select extract(epoch from(st2.absolute_time - st1.absolute_time)) as seconds
            from (select st.effort_id, st.absolute_time
                 from split_times st 
                 where st.lap = #{begin_lap}
                   and st.split_id = #{begin_id}
                   and st.sub_split_bitkey = #{begin_bitkey}
                   and (st.data_status in (#{valid_statuses_list}) or st.data_status is null))
                 as st1,
                 (select st.effort_id, st.absolute_time
                 from split_times st 
                 where st.lap = #{end_lap}
                   and st.split_id = #{end_id}
                   and st.sub_split_bitkey = #{end_bitkey}
                   and (st.data_status in (#{valid_statuses_list}) or st.data_status is null))
                 as st2
            where st1.effort_id = st2.effort_id and #{focus_clause}),

        quartiles as
          (select percentile_cont(0.25) within group (order by seconds) as q1,
                  percentile_cont(0.75) within group (order by seconds) as q3
          from segment_times),
              
        iqr_stats as
          (select q1,
                  q3, 
                  q3 - q1 as iqr
          from quartiles),
          
        bounds as
          (select q1 - (iqr * 1.5) as lower_bound,
                  q3 + (iqr * 1.5) as upper_bound
          from iqr_stats)

      select count(seconds) as effort_count, 
             round(avg(seconds)) as average
      from segment_times
      where seconds between (select lower_bound from bounds) and (select upper_bound from bounds)
    SQL

    result = SplitTime.connection.execute(query.squish)
    casted_row = result.values.first.map { |value| value.is_a?(String) ? value.to_f : value }
    result.fields.zip(casted_row).to_h.with_indifferent_access
  end

  def self.projections(split_time, starting_time_point, subject_time_points)
    unless split_time && starting_time_point && subject_time_points
      raise ArgumentError, 'SplitTimeQuery.projections requires a split_time, starting_time_point, and subject_time_points'
    end

    completed_lap, completed_split_id, completed_bitkey = split_time.time_point.values
    starting_lap, starting_split_id, starting_bitkey = starting_time_point.values
    completed_seconds = split_time.time_from_start

    projected_where_array = subject_time_points.map do |tp|
      "(lap = #{tp.lap} and split_id = #{tp.split_id} and sub_split_bitkey = #{tp.bitkey})"
    end
    projected_where_clause = projected_where_array.join(' or ').presence || 'true'

    overall_limit = 100
    similarity_threshold = 0.3

    query = <<~SQL
      with 
        completed_split_times as
          (select cst.effort_id, 
              cst.absolute_time,
              extract(epoch from(cst.absolute_time - sst.absolute_time)) as completed_segment_seconds,
              abs(extract(epoch from(cst.absolute_time - sst.absolute_time)) - #{completed_seconds}) as difference
          from split_times cst
            inner join split_times sst 
                    on sst.effort_id = cst.effort_id 
                   and sst.lap = #{starting_lap}
                   and sst.split_id = #{starting_split_id}
                   and sst.sub_split_bitkey = #{starting_bitkey}
          where cst.lap = #{completed_lap}
            and cst.split_id = #{completed_split_id}
            and cst.sub_split_bitkey = #{completed_bitkey}
          order by difference
          limit #{overall_limit}),

        main_subquery as
          (select pst.effort_id, 
              lap,
              split_id,
              sub_split_bitkey,
              completed_segment_seconds,
              extract(year from (pst.absolute_time)) as effort_year,
              extract(epoch from(pst.absolute_time - cst.absolute_time)) as projected_segment_seconds
          from completed_split_times cst
            inner join split_times pst on pst.effort_id = cst.effort_id
          where (#{projected_where_clause})
            and difference / #{completed_seconds} < #{similarity_threshold}),

        ratio_subquery as
          (select *,
              case when completed_segment_seconds = 0 
                   then null 
                   else round((projected_segment_seconds / completed_segment_seconds)::numeric, 6) end as ratio
          from main_subquery),
          
        order_count_subquery as
          (select *,
              row_number() over (partition by lap, split_id, sub_split_bitkey order by ratio) as row_number,
              sum(1) over (partition by lap, split_id, sub_split_bitkey) as total
          from ratio_subquery),
          
        quartiles as
            (select lap, 
                split_id, 
                sub_split_bitkey,
                effort_year,
                ratio,
                avg(case when row_number >= (floor(total/2.0)/2.0)
                      and row_number <= (floor(total/2.0)/2.0) + 1
                     then ratio else null end) 
                  over (partition by lap, split_id, sub_split_bitkey) as q1,
                avg(case when row_number >= (total/2.0)
                      and row_number <= (total/2.0) + 1
                     then ratio else null end)
                  over (partition by lap, split_id, sub_split_bitkey) as median,
                avg(case when row_number >= (ceil(total/2.0) + (floor(total/2.0)/2.0))
                      and row_number <= (ceil(total/2.0) + (floor(total/2.0)/2.0) + 1)
                     then ratio else null end)
                  over (partition by lap, split_id, sub_split_bitkey) as q3
            from order_count_subquery),
              
        bounds as
          (select *,
              q3 - q1 as iqr,
              q1 - ((q3 - q1) * 1.5) as lower_bound,
              q3 + ((q3 - q1) * 1.5) as upper_bound
          from quartiles),
              
        valid_ratios as
          (select *
          from bounds
          where ratio between lower_bound and upper_bound),

        stats_subquery as
          (select lap, 
              split_id, 
              sub_split_bitkey,
      				array_to_string(array_agg(distinct effort_year), ',') as effort_years,
              count(ratio) as effort_count,
              round(avg(ratio), 6) as average,
              round(stddev(ratio) * 2, 6) as std2
          from valid_ratios
          group by lap, split_id, sub_split_bitkey),
      
        final_subquery as
          (select lap, 
              split_id, 
              sub_split_bitkey,
              effort_count,
              effort_years,
              case when average >= 0 and (average - std2) is not null
                   then greatest(0, average - std2) 
                   else average - std2 end as low_ratio,
              average as average_ratio,
              average + std2 as high_ratio
          from stats_subquery)
          
      select final_subquery.*, 
          round(low_ratio * #{completed_seconds})::int as low_seconds,
          round(average_ratio * #{completed_seconds})::int as average_seconds,
          round(high_ratio * #{completed_seconds})::int as high_seconds
      from final_subquery
        inner join splits on splits.id = split_id
      order by lap, distance_from_start, sub_split_bitkey
    SQL

    return [] if completed_seconds == 0 || subject_time_points.empty?

    result = SplitTime.connection.execute(query.squish)
    result.values.map do |row|
      Projection.new(result.fields.zip(row).to_h)
    end
  end

  def self.with_time_point_rank(existing_scope)
    existing_scope_subquery = sql_for_existing_scope(existing_scope)

    <<-SQL.squish
      (with existing_scope as (#{existing_scope_subquery}),

          split_times_scoped as 
              (select split_times.*
               from split_times
               inner join existing_scope on existing_scope.id = split_times.id),

          event_ids as
             (select distinct event_id 
              from split_times_scoped 
                join efforts on efforts.id = split_times_scoped.effort_id),

          start_times as
              (select effort_id, absolute_time as start_time
               from split_times
                  join efforts on efforts.id = split_times.effort_id
                  join splits on splits.id = split_times.split_id
               where efforts.event_id in (select event_id from event_ids)
                 and split_times.lap = 1 
                 and splits.kind = #{Split.kinds[:start]}
                 and split_times.sub_split_bitkey = #{SubSplit::IN_BITKEY}),

          elapsed_times as
              (select lap, ast.split_id, ast.sub_split_bitkey, ast.effort_id, distance_from_start,
                      ast.absolute_time - start_times.start_time as elapsed_time
               from split_times ast
                  join efforts on efforts.id = ast.effort_id
                  join splits on splits.id = ast.split_id
                  join start_times on start_times.effort_id = ast.effort_id
               where efforts.event_id in (select event_id from event_ids)),
            
          ranking_subquery as
              (select effort_id, lap, split_id, sub_split_bitkey, distance_from_start,
                  case when distance_from_start = 0 then null else
                       row_number() over (partition by lap, split_id, sub_split_bitkey 
                                          order by lap, distance_from_start, sub_split_bitkey, elapsed_time) end as time_point_rank,
                    case when distance_from_start = 0 then null else
                       array_agg(effort_id) over (partition by lap, split_id, sub_split_bitkey 
                                                  order by lap, distance_from_start, sub_split_bitkey, elapsed_time
                                                  rows between unbounded preceding and 1 preceding) end as effort_ids_ahead
               from elapsed_times)

      select split_times_scoped.*, time_point_rank, effort_ids_ahead
      from split_times_scoped
        left join ranking_subquery using (effort_id, lap, split_id, sub_split_bitkey)
      order by lap, distance_from_start, sub_split_bitkey) as split_times
    SQL
  end

  # It is critical to reset_database_timezone after running this query.
  # Failure to do so will lead to elusive bugs.
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
             trim(both '"' from to_json(st.absolute_time at time zone 'UTC')::text) as absolute_time_local_string,
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
    result = ActiveRecord::Base.connection.execute(query.squish).map { |row| SplitTimeData.new(row) }
    reset_database_timezone
    result
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

    # It is critical to reset_database_timezone after running this query.
    # Failure to do so will lead to elusive bugs.
    query = <<~SQL
      set timezone='#{time_zone}';

      with 
        scoped_split_times as
          (select st.effort_id, st.sub_split_bitkey, st.lap, st.absolute_time at time zone 'UTC' as absolute_time_local
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
           from generate_series((select min(to_timestamp(floor((extract(epoch from absolute_time_local)) / #{band_width}) * #{band_width})) from scoped_split_times), 
                                (select max(to_timestamp(floor((extract(epoch from absolute_time_local)) / #{band_width}) * #{band_width})) + interval '#{band_width} seconds' from scoped_split_times), 
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
          on st.absolute_time_local >= i.start_time and st.absolute_time_local < i.end_time
      where i.end_time is not null
      group by i.start_time, i.end_time
      order by i.start_time
    SQL
    result = ActiveRecord::Base.connection.execute(query.squish).to_a
    reset_database_timezone
    result
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

  def self.shift_event_absolute_times(event, shift_seconds, current_user)
    query = <<-SQL
        with time_subquery as 
           (select st.id, st.absolute_time + (#{shift_seconds} * interval '1 second') as computed_time
            from split_times st
              inner join efforts ef on ef.id = st.effort_id
            where ef.event_id = #{event.id})
          
        update split_times
        set absolute_time = computed_time,
            updated_at = current_timestamp,
            updated_by = #{current_user.id}
        from time_subquery
        where split_times.id = time_subquery.id
    SQL
    query.squish
  end

  def self.existing_scope_sql
    # have to do this to get the binds interpolated. remove any ordering and just grab the ID
    SplitTime.connection.unprepared_statement { SplitTime.reorder(nil).select("id").to_sql }
  end

  def self.sql_for_existing_scope(scope)
    scope.connection.unprepared_statement { scope.reorder(nil).select('id').to_sql }
  end

  def self.valid_statuses_list
    sql_safe_integer_list(SplitTime.valid_statuses)
  end
end
