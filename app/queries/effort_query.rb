# frozen_string_literal: true

class EffortQuery < BaseQuery

  def self.rank_and_finish_status(args = {})
    select_sql = sql_select_from_string(args[:fields], permitted_column_names, '*')
    order_sql = sql_order_from_hash(args[:sort], permitted_column_names, 'overall_rank')
    query = <<-SQL
      WITH
        existing_scope AS (#{existing_scope_sql}),
        efforts_scoped AS (SELECT efforts.*
                                       FROM efforts
                                       INNER JOIN existing_scope ON existing_scope.id = efforts.id)

      SELECT #{select_sql},
          rank() over 
            (ORDER BY dropped, 
                      final_lap desc, 
                      final_lap_distance desc, 
                      final_bitkey desc, 
                      final_time, 
                      gender desc, 
                      age desc) 
          AS overall_rank, 
          rank() over 
            (PARTITION BY gender 
             ORDER BY dropped, 
                      final_lap desc, 
                      final_lap_distance desc, 
                      final_bitkey desc, 
                      final_time, 
                      gender desc, 
                      age desc) 
          AS gender_rank
      FROM
        (SELECT *,
          CASE
            when stopped and not finished then true else false
          END
          AS dropped
        FROM
          (SELECT *,
              CASE
                when finished or stopped_split_time_id is not null then true else false 
              end 
              AS stopped
          FROM
            (SELECT *,
                CASE 
                when laps_required = 0 then
                  CASE when stopped_split_time_id is null then false else true END  
                else
                  CASE when laps_finished >= laps_required then true else false END 
                END
                AS finished
            FROM
              (SELECT *, 
                  true AS started,
                  final_lap AS laps_started,
                  CASE
                    when final_lap_complete is true then final_lap 
                    else final_lap - 1 
                  end 
                  AS laps_finished,
                  (final_lap - 1) * course_distance + final_lap_distance AS final_distance,
                  event_start_time
              FROM 
                (SELECT DISTINCT ON(efforts_scoped.id) 
                    efforts_scoped.*,
                    events.laps_required,
                    events.start_time as event_start_time,
                    events.home_time_zone as event_home_zone,
                    splits.base_name as final_split_name,
                    splits.distance_from_start as final_lap_distance,
                    split_times.lap as final_lap,
                    split_times.split_id as final_split_id, 
                    split_times.sub_split_bitkey as final_bitkey,
                    split_times.time_from_start as final_time,
                    split_times.id as final_split_time_id,
                    stopped_split_time_id,
                    stopped_lap,
                    stopped_split_id,
                    stopped_bitkey,
                    stopped_time,
                    CASE
                        when splits.kind = 1 then true 
                        else false 
                        end 
                      AS final_lap_complete,
                      course_distance
                FROM efforts_scoped
                    INNER JOIN split_times ON split_times.effort_id = efforts_scoped.id 
                    INNER JOIN splits ON splits.id = split_times.split_id
                    INNER JOIN events ON events.id = efforts_scoped.event_id
                    INNER JOIN (SELECT courses.id as course_id, splits.distance_from_start as course_distance
                        FROM courses
                        INNER JOIN splits ON splits.course_id = courses.id
                        WHERE splits.kind = 1)
                  AS course_subquery ON events.course_id = course_subquery.course_id
                  LEFT OUTER JOIN (SELECT split_times.id as stopped_split_time_id, 
                             split_times.lap as stopped_lap, 
                             split_times.split_id as stopped_split_id, 
                             split_times.sub_split_bitkey as stopped_bitkey, 
                             split_times.time_from_start as stopped_time, 
                             split_times.effort_id
                        FROM split_times
                        WHERE split_times.stopped_here = true)
                  AS stopped_subquery ON split_times.effort_id = stopped_subquery.effort_id
                ORDER BY  efforts_scoped.id, 
                      final_lap desc,
                          final_lap_distance desc, 
                          final_bitkey desc,
                          stopped_time desc)
                AS base_subquery)
              AS distance_subquery)
            AS finished_subquery)
          AS stopped_subquery)
        AS dropped_subquery
      ORDER BY #{order_sql}
    SQL
    query.squish
  end

  def self.over_segment(segment)
    begin_id = segment.begin_id
    begin_bitkey = segment.begin_bitkey
    end_id = segment.end_id
    end_bitkey = segment.end_bitkey

    query = <<-SQL
      WITH
        existing_scope AS (#{existing_scope_sql}),
        efforts_scoped AS (SELECT efforts.*
                                       FROM efforts
                                       INNER JOIN existing_scope ON existing_scope.id = efforts.id)

      SELECT *, 
              lap, 
              rank() over (order by segment_seconds, gender, -age, lap) as overall_rank, 
              rank() over (partition by gender order by segment_seconds, -age) as gender_rank,
              true as started
      FROM 
        (SELECT e1.*, (tfs_end - tfs_begin) as segment_seconds 
        FROM 
            (SELECT efforts_scoped.*, 
                    events.start_time as event_start_time, 
                    events.home_time_zone as event_home_zone, 
                    split_times.effort_id, 
                    split_times.time_from_start as tfs_begin, 
                    split_times.lap, 
                    split_times.split_id, 
                    split_times.sub_split_bitkey,
                    events.laps_required,
                    event_groups.concealed as event_group_concealed
            FROM efforts_scoped
              INNER JOIN split_times ON split_times.effort_id = efforts_scoped.id 
              INNER JOIN events ON events.id = efforts_scoped.event_id
              INNER JOIN event_groups ON event_groups.id = events.event_group_id
            WHERE split_times.split_id = #{begin_id} AND split_times.sub_split_bitkey = #{begin_bitkey}) 
        as e1, 
            (SELECT efforts_scoped.id, 
                    split_times.effort_id, 
                    split_times.time_from_start as tfs_end, 
                    split_times.lap, 
                    split_times.split_id, 
                    split_times.sub_split_bitkey 
            FROM efforts_scoped
            INNER JOIN split_times ON split_times.effort_id = efforts_scoped.id 
            WHERE split_times.split_id = #{end_id} AND split_times.sub_split_bitkey = #{end_bitkey}) 
        as e2 
        WHERE (e1.effort_id = e2.effort_id AND e1.lap = e2.lap)) 
      as efforts 
      WHERE event_group_concealed = 'f'
      ORDER BY overall_rank
    SQL
    query.squish
  end

  def self.existing_scope_sql
    # have to do this to get the binds interpolated. remove any ordering and just grab the ID
    Effort.connection.unprepared_statement { Effort.reorder(nil).select('id').to_sql }
  end

  def self.permitted_column_names
    EffortParameters.enriched_query
  end
end
