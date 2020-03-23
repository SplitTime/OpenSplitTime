class OrderedEffortsAtTimePoint
  include ActiveModel::Model
  include ActiveModel::Attributes

  attribute :lap, :integer
  attribute :split_id, :integer
  attribute :sub_split_bitkey, :integer
  attribute :effort_ids, :integer_array_from_string
end
