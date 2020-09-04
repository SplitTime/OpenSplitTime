# frozen_string_literal: true

# Inherit from ::ApplicationQuery when you have a class
# that is dedicated to receiving the results of a specific
# raw SQL query.
#
class ApplicationQuery
  include ::ActiveModel::Model
  include ::ActiveModel::Attributes

  NULL_QUERY = "select * from generate_series(0, -1) x;"

  def self.execute_query(*args)
    query = sql(*args)
    result = ::ActiveRecord::Base.connection.execute(query)
    result.map { |row| new(row) }
  end
end
