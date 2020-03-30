# frozen_string_literal: true

module Query
  class Base
    def self.sql_for_existing_scope(scope)
      scope.connection.unprepared_statement { scope.reorder(nil).select('id').to_sql }
    end
  end
end
