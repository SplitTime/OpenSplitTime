class AidStationResource < Madmin::Resource
  # Attributes
  attribute :id, form: false
  attribute :created_at, form: false
  attribute :updated_at, form: false

  # Associations
  attribute :event, index: true
  attribute :split, index: true

  def self.display_name(record)
    "#{record.event.name}: #{record.split.base_name}"
  end

  # Uncomment this to customize the default sort column and direction.
  # def self.default_sort_column
  #   "created_at"
  # end
  #
  # def self.default_sort_direction
  #   "desc"
  # end
end
