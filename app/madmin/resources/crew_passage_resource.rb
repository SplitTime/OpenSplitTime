class CrewPassageResource < Madmin::Resource
  # Attributes
  attribute :id, form: false
  attribute :passed_at
  attribute :created_at, form: false
  attribute :updated_at, form: false

  # Associations
  attribute :gating_location
  attribute :effort
end
