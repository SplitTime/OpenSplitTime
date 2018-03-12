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
      SELECT AVG(st2.time_from_start - st1.time_from_start) AS segment_time,
             COUNT(st1.time_from_start) AS effort_count
      FROM (SELECT st.effort_id, st.time_from_start
           FROM split_times st 
           WHERE st.lap = #{begin_lap} 
             AND st.split_id = #{begin_id} 
             AND st.sub_split_bitkey = #{begin_bitkey}
             AND (st.data_status IN (#{valid_statuses_list}) OR st.data_status IS NULL))
           AS st1,
           (SELECT st.effort_id, st.time_from_start
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

  def self.with_time_point_rank(split_time_fields: '*')
    query = <<-SQL
      WITH
        existing_scope AS (#{existing_scope_sql}),
        split_times_scoped AS (SELECT split_times.*
                                       FROM split_times
                                       INNER JOIN existing_scope ON existing_scope.id = split_times.id)

      SELECT *, 
            rank() over 
                (PARTITION BY lap, 
                              split_id, 
                              sub_split_bitkey 
                ORDER BY subquery_time, 
                         effort_gender desc, 
                         effort_age desc,
                         tiebreaker_id) 
            as time_point_rank,
            day_and_time,
            event_home_zone
      FROM
          (SELECT time_from_start as subquery_time, #{split_time_fields}, 
            (events.start_time + efforts.start_offset * interval '1 second' + time_from_start * interval '1 second') as day_and_time,
            efforts.gender as effort_gender, efforts.age as effort_age, efforts.id as tiebreaker_id, events.home_time_zone as event_home_zone
          FROM split_times_scoped
          INNER JOIN efforts ON efforts.id = split_times_scoped.effort_id
          INNER JOIN events ON events.id = efforts.event_id
          WHERE time_from_start > 0) 
          AS subquery
      ORDER BY time_point_rank
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
