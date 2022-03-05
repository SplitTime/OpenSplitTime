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
    Effort.connection.unprepared_statement { Effort.reorder(nil).select("id").to_sql }
  end

  def self.sql_for_existing_scope(scope)
    scope.connection.unprepared_statement { scope.reorder(nil).select("id").to_sql }
  end

  def self.permitted_column_names
    EffortParameters.enriched_query
  end
end
