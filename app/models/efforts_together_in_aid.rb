# frozen_string_literal: true

class EffortsTogetherInAid
  include ::ActiveModel::Model
  include ::ActiveModel::Attributes

  attribute :effort_id, :integer
  attribute :lap, :integer
  attribute :split_id, :integer
  attribute :together_effort_ids, :integer_array_from_string

  def self.execute_query(effort_id)
    query = ::Query::EffortsTogetherInAid.sql(effort_id)
    result = ::ActiveRecord::Base.connection.execute(query)
    result.map { |row| new(row) }
  end

  def lap_split_key
    LapSplitKey.new(lap, split_id)
  end
end
