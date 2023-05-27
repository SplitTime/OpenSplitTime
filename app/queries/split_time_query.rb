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
    focus_clause = effort_ids.present? ? "st1.effort_id IN (#{sql_safe_integer_list(effort_ids)})" : "true"

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
    lowest_time = args[:time_range].begin
    highest_time = args[:time_range].end
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

  def self.set_effort_elapsed_times(effort_id)
    start_lap = 1
    start_kind = ::Split.kinds[:start]
    in_bitkey = ::SubSplit::IN_BITKEY

    <<~SQL.squish
      with start_time as
               (select absolute_time
                from split_times
                         join splits on splits.id = split_times.split_id
                where effort_id = #{effort_id}
                  and lap = #{start_lap}
                  and kind = #{start_kind}
                  and sub_split_bitkey = #{in_bitkey})

      update split_times
      set elapsed_seconds = extract(epoch from (split_times.absolute_time - (select absolute_time from start_time)))
      where effort_id = #{effort_id};
    SQL
  end

  def self.shift_event_absolute_times(event, shift_seconds)
    query = <<-SQL
        with time_subquery as 
           (select st.id, st.absolute_time + (#{shift_seconds} * interval '1 second') as computed_time
            from split_times st
              inner join efforts ef on ef.id = st.effort_id
            where ef.event_id = #{event.id})
          
        update split_times
        set absolute_time = computed_time,
            updated_at = current_timestamp
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
    scope.connection.unprepared_statement { scope.reorder(nil).select("id").to_sql }
  end

  def self.valid_statuses_list
    sql_safe_integer_list(SplitTime.valid_statuses)
  end
end
