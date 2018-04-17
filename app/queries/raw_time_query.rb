class RawTimeQuery < BaseQuery

  def self.with_relations(event_group_id)

    query = <<-SQL

    WITH existing_scope AS (#{existing_scope_sql}),
         raw_times_scoped AS (
           SELECT raw_times.*
           FROM raw_times
           INNER JOIN existing_scope ON existing_scope.id = raw_times.id),
         relevant_splits AS (
           SELECT splits.id AS split_id, events.id AS event_id, parameterized_base_name
           FROM splits
           INNER JOIN aid_stations ON aid_stations.split_id = splits.id
           INNER JOIN events ON events.id = aid_stations.event_id
           WHERE events.event_group_id = #{event_group_id}
      ), relevant_efforts AS (
           SELECT efforts.id AS effort_id, efforts.event_id AS event_id, efforts.bib_number::text AS effort_bib_number
           FROM efforts
           INNER JOIN events ON events.id = efforts.event_id
           WHERE events.event_group_id = #{event_group_id}
    )

    SELECT raw_times_scoped.*, relevant_efforts.effort_id AS effort_id, relevant_efforts.event_id AS event_id, relevant_splits.split_id AS split_id
    FROM raw_times_scoped
    LEFT JOIN relevant_efforts ON relevant_efforts.effort_bib_number = raw_times_scoped.bib_number
    LEFT JOIN relevant_splits ON relevant_splits.parameterized_base_name = raw_times_scoped.parameterized_split_name
        AND relevant_splits.event_id = relevant_efforts.event_id
    SQL
    query.squish
  end

  def self.existing_scope_sql
    # have to do this to get the binds interpolated. remove any ordering and just grab the ID
    RawTime.connection.unprepared_statement { RawTime.reorder(nil).select('id').to_sql }
  end
end
