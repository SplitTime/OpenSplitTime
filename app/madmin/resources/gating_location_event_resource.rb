class GatingLocationEventResource < Madmin::Resource
  # Attributes
  attribute :id, form: false
  attribute :created_at, form: false
  attribute :updated_at, form: false

  # Associations
  attribute :gating_location, index: true
  attribute :event, index: true
  attribute :gating_aid_station, index: true
  attribute :target_aid_station, index: true
end
