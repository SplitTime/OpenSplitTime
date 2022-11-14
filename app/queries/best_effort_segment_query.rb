# frozen_string_literal: true

class BestEffortSegmentQuery < BaseQuery
  # @param [ActiveRecord::ActiveRecordRelation] existing_scope
  # @return [String]
  def self.finish_count_subquery(existing_scope)
    existing_scope_subquery = full_sql_for_existing_scope(existing_scope)

    <<~SQL.squish
      (with existing_scope as (
              #{existing_scope_subquery}
            ),

      effort_counts as (
        select person_id, count(*) as finish_count
        from existing_scope
        group by person_id
      )

      select existing_scope.*, effort_counts.finish_count
      from existing_scope
        join effort_counts using (person_id)) best_effort_segments
    SQL
  end
end
