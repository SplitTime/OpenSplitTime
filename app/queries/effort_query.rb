class EffortQuery

  def self.with_finish_status(effort_fields: '*')
    query = <<-SQL
      WITH
        existing_scope AS (#{existing_scope_sql}),
        efforts_scoped AS (SELECT efforts.*
                                       FROM efforts
                                       INNER JOIN existing_scope ON existing_scope.id = efforts.id)

      SELECT *, 
            CASE 
              when laps_required = 0 then 
                CASE
                  when dropped_split_id is null then false
                  else true
                end  
              else
                CASE
                  when laps_finished >= laps_required then true 
                  else false 
                END 
            END
            AS finished
      FROM
          (SELECT #{effort_fields}, 
                rank() over 
                  (ORDER BY dropped, 
                            final_lap desc, 
                            final_lap_distance desc, 
                            final_time, 
                            gender desc, 
                            age desc) 
                AS overall_rank, 
                rank() over 
                  (PARTITION BY gender 
                   ORDER BY dropped, 
                            final_lap desc, 
                            final_lap_distance desc, 
                            final_time, 
                            gender desc, 
                            age desc) 
                AS gender_rank,
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
                    CASE 
                      when laps_required = 0 then false
                      else
                        CASE
                          when efforts_scoped.dropped_split_id is null then false 
                          else true 
                        END 
                    END
                    AS dropped, 
                    splits.base_name as final_split_name,
                    splits.distance_from_start as final_lap_distance,
                    split_times.lap as final_lap,
                    split_times.split_id as final_split_id, 
                    split_times.sub_split_bitkey as final_bitkey,
                    split_times.time_from_start as final_time,
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
                
                ORDER BY efforts_scoped.id, 
                         final_lap desc,
                         final_lap_distance desc, 
                         final_bitkey desc) 
                AS subquery)
          AS all_but_finished
      ORDER BY overall_rank
    SQL
    query.squish
  end

  def self.existing_scope_sql
    # have to do this to get the binds interpolated. remove any ordering and just grab the ID
    Effort.connection.unprepared_statement { Effort.reorder(nil).select('id').to_sql }
  end
end