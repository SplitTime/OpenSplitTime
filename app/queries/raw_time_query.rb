class RawTimeQuery < BaseQuery
  def self.with_relations(existing_scope, args = {})
    existing_scope = existing_scope_sql(existing_scope)
    order_sql = sql_order_from_hash(args[:sort], permitted_column_names, "sortable_bib_number")

    <<-SQL.squish
      with existing_scope as (
             #{existing_scope}
           ),

           raw_times_scoped AS (
               SELECT raw_times.*
               FROM raw_times
               INNER JOIN existing_scope ON existing_scope.id = raw_times.id
           ),
           
           relevant_efforts as (
               select ef.bib_number, ef.id as effort_id, ef.last_name, ev.course_id, ev.id as event_id
               from events ev
               inner join efforts ef on ef.event_id = ev.id
               where ev.event_group_id in (select distinct event_group_id from raw_times_scoped)
           ),
           
           relevant_splits as (
               select parameterized_base_name, s.id as split_id, s.course_id
               from splits s
               where s.course_id in (select distinct course_id from relevant_efforts)
           )

      select
           r.*, 
           re.effort_id,
           re.last_name as effort_last_name,
           re.event_id, 
           rs.split_id
      from raw_times_scoped r
        left join relevant_efforts re 
               on r.matchable_bib_number is not null 
              and re.bib_number = r.matchable_bib_number
        left join relevant_splits rs 
               on rs.parameterized_base_name = r.parameterized_split_name
              and rs.course_id = re.course_id
      order by #{order_sql}, r.id
    SQL
  end

  def self.delete_duplicates(event_group, scope = {})
    hash = {rt: {event_group_id: event_group.id}}.merge(scope)
    scope_string = BaseQuery.where_string_from_hash(hash)

    query = <<~SQL
      delete from raw_times
      where id in
        (select id from
          (select id, event_group_id,
                  row_number() over
                    (partition by event_group_id, 
                                  bib_number, 
                                  parameterized_split_name, 
                                  bitkey, 
                                  absolute_time,
                                  case when absolute_time is null then entered_time else null end,
                                  stopped_here, 
                                  with_pacer, 
                                  source
                     order by id)
              as row_num
           from raw_times) rt
        where rt.row_num > 1 and #{scope_string})
    SQL
    query.squish
  end

  def self.existing_scope_sql(scope)
    # have to do this to get the binds interpolated. remove any ordering and just grab the ID
    scope.connection.unprepared_statement { scope.reorder(nil).select("id").to_sql }
  end

  def self.permitted_column_names
    RawTimeParameters.enriched_query
  end
end
