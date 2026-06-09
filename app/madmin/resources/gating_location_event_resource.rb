class GatingLocationEventResource < Madmin::Resource
  # Attributes
  attribute :id, form: false
  attribute :created_at, form: false
  attribute :updated_at, form: false

  # Associations
  attribute :gating_location
  attribute :event
  attribute :gating_aid_station
  attribute :target_aid_station
end
