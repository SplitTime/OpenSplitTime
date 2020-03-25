class OrderedEffortsAtTimePoint
  include ActiveModel::Model
  include ActiveModel::Attributes

  attribute :lap, :integer
  attribute :split_id, :integer
  attribute :sub_split_bitkey, :integer
  attribute :effort_ids, :integer_array_from_string

  def time_point
    TimePoint.new(lap, split_id, sub_split_bitkey)
  end
end
