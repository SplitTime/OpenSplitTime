class CrewPassageResource < Madmin::Resource
  # Attributes
  attribute :id, form: false
  attribute :passed_at, index: true
  attribute :created_at, form: false
  attribute :updated_at, form: false

  # Associations
  attribute :gating_location, index: true
  attribute :effort, index: true
end
