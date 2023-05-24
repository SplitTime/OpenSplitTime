class ResultsTemplate < ApplicationRecord
  include Auditable
  extend FriendlyId

  enum aggregation_method: [:inclusive, :strict]
  friendly_id :organization_and_name, use: [:slugged, :history]

  belongs_to :organization, optional: true
  has_many :results_template_categories, -> { order(position: :asc) }, dependent: :destroy
  has_many :results_categories, through: :results_template_categories

  alias_attribute :categories, :results_categories

  scope :standard, lambda {
                     select("results_templates.*, count(results_categories.id) as category_count")
                         .joins(:results_categories).where(organization: nil).group(:id).order("category_count")
                   }

  validates_presence_of :name, :aggregation_method, :identifier

  before_validation :set_identifier

  def self.default
    find_by(identifier: "simple")
  end

  def dup_with_categories
    # This must be done first or relations will be lost
    set_category_positions

    template = dup
    template.results_categories = results_categories.map(&:dup)
    template
  end

  private

  def organization_and_name
    [organization&.name, name].compact.join(" ")
  end

  def set_category_positions
    indexed_rtcs = results_template_categories.index_by(&:results_category_id)

    results_categories.each do |rc|
      rtc = indexed_rtcs[rc.id]
      rc.position = rtc.position
      rc.fixed_position = rtc.fixed_position
    end
  end

  def set_identifier
    self.identifier = slug.tr("-", "_")
  end
end
