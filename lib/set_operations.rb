module SetOperations
  extend ActiveSupport::Concern

  class_methods do

    def union_scope(*scopes)
      apply_operation 'UNION', scopes
    end

    def intersect_scope(*scopes)
      apply_operation 'INTERSECT', scopes
    end

    def except_scope(*scopes)
      apply_operation 'EXCEPT', scopes
    end

    private

    def apply_operation(operation, scopes)
      id_column = "#{table_name}.#{primary_key}"
      sub_query = scopes
                      .map { |s| s.blank? ? nil : s.select(id_column).to_sql }
                      .compact
                      .join(" #{operation} ")

      return none if sub_query.blank?

      where "#{id_column} IN (#{sub_query})"
    end

  end
end
