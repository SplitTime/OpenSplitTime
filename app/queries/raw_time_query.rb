class RawTimeQuery < BaseQuery

  def self.with_relations

    query = <<-SQL

    WITH existing_scope AS (#{existing_scope_sql}),
         raw_times_scoped AS (
           SELECT raw_times.*
           FROM raw_times
           INNER JOIN existing_scope ON existing_scope.id = raw_times.id)

    SELECT 
       r.*
       , e.id AS effort_id
       , e.event_id
       , (SELECT split_id FROM aid_stations a
          INNER JOIN splits s ON a.split_id = s.id
          WHERE a.event_id = e.event_id
          AND s.parameterized_base_name = r.parameterized_split_name
          limit 1) AS split_id
    FROM raw_times_scoped r
    LEFT JOIN efforts e ON r.bib_number = e.bib_number::text
       AND e.event_id IN 
          (SELECT id 
           FROM events 
           WHERE events.event_group_id = r.event_group_id)
    ORDER BY r.bib_number, r.id
    SQL
    query.squish
  end

  def self.existing_scope_sql
    # have to do this to get the binds interpolated. remove any ordering and just grab the ID
    RawTime.connection.unprepared_statement { RawTime.reorder(nil).select('id').to_sql }
  end
end
