# frozen_string_literal: true

class EffortQuery < BaseQuery
  def self.rank_and_status(args = {})
    select_sql = sql_select_from_string(args[:fields], permitted_column_names, "*")
    order_sql = sql_order_from_hash(args[:sort], permitted_column_names, "event_id,overall_rank")
    where_clause = args[:effort_id].present? ? "where id = #{args[:effort_id]}" : ""

    <<~NEW_SQL.squish
      with existing_scope as (
          #{existing_scope_sql}
      ),

           efforts_scoped as (
               select efforts.*
               from efforts
                        inner join existing_scope on existing_scope.id = efforts.id
           )

      select #{select_sql}
      from efforts_scoped
          #{where_clause}
      order by #{order_sql}
    NEW_SQL
  end

  def self.finish_info_subquery(existing_scope)
    existing_scope_subquery = sql_for_existing_scope(existing_scope)

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

      select efforts.*,
             base_name                                                              as final_split_name,
             absolute_time                                                          as final_absolute_time,
             elapsed_seconds                                                        as final_elapsed_seconds,
             split_times.lap                                                        as final_lap,
             (split_times.lap - 1) * course_distance + splits.distance_from_start   as final_distance,
             (split_times.lap - 1) * course_vert_gain + splits.vert_gain_from_start as final_vert_gain
      from efforts
               join split_times on split_times.id = efforts.final_split_time_id
               join splits on splits.id = split_times.split_id
               join course_subquery using(course_id)
      where efforts.id in (select id from existing_scope)
      )

      as efforts
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
           )

      select
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
          ef.started,
          ef.beyond_start,
          sst.absolute_time                                                                     as actual_start_time,
          coalesce(ef.scheduled_start_time, ev.scheduled_start_time)                            as assumed_start_time,
          extract(epoch from (ef.scheduled_start_time - ev.scheduled_start_time))               as scheduled_start_offset,
          (checked_in and not started and
              (coalesce(ef.scheduled_start_time, ev.scheduled_start_time) < current_timestamp)) as ready_to_start
      from efforts ef
               join events ev on ev.id = ef.event_id
               left join starting_split_times sst on sst.effort_id = ef.id
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
    Effort.connection.unprepared_statement { Effort.reorder(nil).select("id").to_sql }
  end

  def self.sql_for_existing_scope(scope)
    scope.connection.unprepared_statement { scope.reorder(nil).select("id").to_sql }
  end

  def self.permitted_column_names
    EffortParameters.enriched_query
  end
end
