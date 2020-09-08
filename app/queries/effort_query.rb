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
                           events.scheduled_start_time                                 as event_start_time,
                           event_groups.home_time_zone,
                           splits.base_name                                            as final_split_name,
                           splits.distance_from_start                                  as final_lap_distance,
                           splits.vert_gain_from_start                                 as final_lap_vert_gain,
                           split_times.lap                                             as final_lap,
                           split_times.split_id                                        as final_split_id,
                           split_times.sub_split_bitkey                                as final_bitkey,
                           split_times.absolute_time                                   as final_absolute_time,
                           split_times.elapsed_seconds                                 as final_elapsed_seconds,
                           split_times.id                                              as final_split_time_id,
                           stopped_split_time_id,
                           stopped_lap,
                           stopped_split_id,
                           stopped_bitkey,
                           stopped_absolute_time,
                           course_distance,
                           course_vert_gain,
                           case when splits.kind = 1 then true else false end          as final_lap_complete
                from efforts_scoped
                         left join split_times on split_times.effort_id = efforts_scoped.id
                         left join splits on splits.id = split_times.split_id
                         left join events on events.id = efforts_scoped.event_id
                         inner join event_groups on event_groups.id = events.event_group_id
                         left join course_subquery on events.course_id = course_subquery.course_id
                         left join stopped_split_times stop_st on split_times.effort_id = stop_st.effort_id
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
                           as finished
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

  def self.roster_subquery(existing_scope)
    existing_scope_subquery = sql_for_existing_scope(existing_scope)

    <<~SQL.squish
      (with 
           existing_scope as (
               #{existing_scope_subquery}
           ),

           starting_split_times as (
               select effort_id, absolute_time
               from split_times
                        join splits on splits.id = split_times.split_id
               where kind = 0
                 and lap = 1
           ),

           beyond_start_split_times as (
               select effort_id
               from split_times
                        join splits on splits.id = split_times.split_id
               where kind != 0
                  or lap != 1
           )

      select distinct on (ef.id) 
          ef.id, 
          ef.slug, 
          ef.event_id, 
          ef.person_id, 
          ef.bib_number, 
          ef.city, 
          ef.state_code, 
          ef.country_code, 
          ef.age, 
          ef.gender, 
          ef.first_name, 
          ef.last_name, 
          ef.birthdate, 
          ef.data_status, 
          ef.checked_in, 
          ef.emergency_contact, 
          ef.emergency_phone,
          sst.absolute_time                                                                     as actual_start_time,
          sst.absolute_time is not null                                                         as started,
          bsst.effort_id is not null                                                            as beyond_start,
          coalesce(ef.scheduled_start_time, ev.scheduled_start_time)                            as assumed_start_time,
          extract(epoch from (ef.scheduled_start_time - ev.scheduled_start_time))               as scheduled_start_offset,
          (checked_in and 
              sst.absolute_time is null and 
              (coalesce(ef.scheduled_start_time, ev.scheduled_start_time) < current_timestamp)) as ready_to_start
      from efforts ef
               join events ev on ev.id = ef.event_id
               left join starting_split_times sst on sst.effort_id = ef.id
               left join beyond_start_split_times bsst on bsst.effort_id = ef.id
      where ef.id in (select id from existing_scope)
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
    Effort.connection.unprepared_statement { Effort.reorder(nil).select('id').to_sql }
  end

  def self.sql_for_existing_scope(scope)
    scope.connection.unprepared_statement { scope.reorder(nil).select('id').to_sql }
  end

  def self.permitted_column_names
    EffortParameters.enriched_query
  end
end
