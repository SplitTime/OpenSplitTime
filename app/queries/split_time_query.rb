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
      SELECT AVG(st2.absolute_time - st1.absolute_time) AS segment_time,
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

  def self.existing_scope_sql
    # have to do this to get the binds interpolated. remove any ordering and just grab the ID
    SplitTime.connection.unprepared_statement { SplitTime.reorder(nil).select("id").to_sql }
  end

  def self.valid_statuses_list
    sql_safe_integer_list(SplitTime.valid_statuses)
  end
end
