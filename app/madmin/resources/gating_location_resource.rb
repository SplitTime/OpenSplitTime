class GatingLocationResource < Madmin::Resource
  # Attributes
  attribute :id, form: false
  attribute :name
  attribute :created_at, form: false
  attribute :updated_at, form: false

  # Associations
  attribute :event_group, index: true

  def self.display_name(record)
    "#{record.event_group.name}: #{record.name}"
  end
end
