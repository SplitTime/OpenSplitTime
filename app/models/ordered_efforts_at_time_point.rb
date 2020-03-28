# frozen_string_literal: true

class OrderedEffortsAtTimePoint
  include ::ActiveModel::Model
  include ::ActiveModel::Attributes

  attribute :lap, :integer
  attribute :split_id, :integer
  attribute :sub_split_bitkey, :integer
  attribute :effort_ids, :integer_array_from_string

  def self.execute_query(event_id)
    query = ::Query::OrderedEffortsAtTimePoint.sql(event_id)
    result = ::ActiveRecord::Base.connection.execute(query).to_a
    result.map { |row| new(row) }
  end

  def time_point
    ::TimePoint.new(lap, split_id, sub_split_bitkey)
  end
end
