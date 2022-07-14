# frozen_string_literal: true

class EffortQuery < BaseQuery
  def self.ranking_subquery(existing_scope)
    existing_scope_subquery = full_sql_for_existing_scope(existing_scope)

    <<~SQL.squish
      (with existing_scope as (
              #{existing_scope_subquery}
            ),

           event_subquery as (
               select distinct on (event_id) event_id
               from efforts
               where efforts.id in (select id from existing_scope)
           ),

           efforts_for_ranking as (
               select id as effort_id, event_id, gender, overall_performance, bib_number
               from efforts
               where efforts.event_id in (select event_id from event_subquery)
           ),

           ranking_subquery as (
               select effort_id,
                      rank() over overall_window                   as overall_rank,
                      rank() over gender_window                    as gender_rank,
                      lag(effort_id) over overall_window_with_bib  as prior_effort_id,
                      lead(effort_id) over overall_window_with_bib as next_effort_id,
                      bib_number
               from efforts_for_ranking
               window overall_window as (partition by event_id order by overall_performance desc),
                      gender_window as (partition by event_id, gender order by overall_performance desc),
                      overall_window_with_bib as (partition by event_id order by overall_performance desc, bib_number asc)
           )

      select existing_scope.*,
             overall_rank,
             gender_rank,
             prior_effort_id,
             next_effort_id
      from existing_scope
           join ranking_subquery on ranking_subquery.effort_id = existing_scope.id
      order by event_id, overall_rank, ranking_subquery.bib_number
      )

      as efforts
    SQL
  end

  def self.finish_info_subquery(existing_scope)
    existing_scope_subquery = full_sql_for_existing_scope(existing_scope)

    <<~SQL.squish
      (with existing_scope as (
        #{existing_scope_subquery}
      ),

           event_subquery as (
               select event_id
               from efforts
               where efforts.id in (select id from existing_scope)
           ),

           course_subquery as (
               select courses.id                  as course_id,
                      splits.distance_from_start  as course_distance,
                      splits.vert_gain_from_start as course_vert_gain
               from courses
                        join splits on splits.course_id = courses.id
                        join events on events.course_id = courses.id
               where splits.kind = 1
                 and events.id in (select event_id from event_subquery)
           )

      select distinct on(existing_scope.id)
             existing_scope.*,
             stop_st.lap                                                         as stopped_lap,
             stop_st.split_id                                                    as stopped_split_id,
             final_st.lap                                                        as final_lap,
             splits.id                                                           as final_split_id,
             final_st.sub_split_bitkey                                           as final_bitkey,
             splits.base_name                                                    as final_split_name,
             final_st.absolute_time                                              as final_absolute_time,
             final_st.elapsed_seconds                                            as final_elapsed_seconds,
             (final_st.lap - 1) * course_distance + splits.distance_from_start   as final_distance,
             (final_st.lap - 1) * course_vert_gain + splits.vert_gain_from_start as final_vert_gain
      from existing_scope
               left join split_times stop_st on stop_st.id = existing_scope.stopped_split_time_id
               left join split_times final_st on final_st.id = existing_scope.final_split_time_id
               left join splits on splits.id = final_st.split_id
               left join course_subquery using(course_id)
      )

      as efforts
    SQL
  end

  def self.roster_subquery(existing_scope)
    existing_scope_subquery = full_sql_for_existing_scope(existing_scope)

    <<~SQL.squish
      (with 
           existing_scope as (
               #{existing_scope_subquery}
           ),

           starting_split_times as (
               select effort_id, absolute_time
               from split_times
                        join splits on splits.id = split_times.split_id
               where split_times.effort_id in (select id from existing_scope)
                 and kind = 0
                 and lap = 1
           )

      select
          es.*,
          sst.absolute_time                                                                     as actual_start_time,
          coalesce(es.scheduled_start_time, ev.scheduled_start_time)                            as assumed_start_time,
          extract(epoch from (es.scheduled_start_time - ev.scheduled_start_time))               as scheduled_start_offset,
          (checked_in and sst.absolute_time is null and
              (coalesce(es.scheduled_start_time, ev.scheduled_start_time) < current_timestamp)) as ready_to_start
      from existing_scope es
               join events ev on ev.id = es.event_id
               left join starting_split_times sst on sst.effort_id = es.id
      )

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
    Effort.connection.unprepared_statement { Effort.reorder(nil).select("id").to_sql }
  end

  def self.sql_for_existing_scope(scope)
    scope.connection.unprepared_statement { scope.reorder(nil).select("id").to_sql }
  end

  def self.full_sql_for_existing_scope(scope)
    scope.connection.unprepared_statement { scope.reorder(nil).to_sql }
  end

  def self.permitted_column_names
    EffortParameters.enriched_query
  end
end
