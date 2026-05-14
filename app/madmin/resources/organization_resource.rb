class OrganizationResource < Madmin::Resource
  # Attributes
  attribute :id, form: false
  attribute :name, index: true
  attribute :description
  attribute :created_at, form: false
  attribute :updated_at, form: false
  attribute :created_by, index: true
  attribute :concealed, index: true
  attribute :non_profit, index: true
  attribute :slug, index: true

  # Associations
  attribute :slugs
  attribute :versions
  attribute :courses
  attribute :course_groups
  attribute :event_groups
  attribute :lotteries
  attribute :stewardships
  attribute :stewards
  attribute :event_series
  attribute :results_templates

  # Drives the label on belongs_to dropdowns (e.g. MonetaryDonation's "Organization" field)
  # and the heading on each org's show page. Without this, madmin falls back to
  # "Organization #4".
  def self.display_name(record)
    record.name
  end

  def self.default_sort_column
    "name"
  end

  def self.default_sort_direction
    "asc"
  end
end
