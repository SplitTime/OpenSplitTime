class ResultsTemplate < ApplicationRecord
  include Auditable
  extend FriendlyId

  enum aggregation_method: [:inclusive, :strict]
  friendly_id :name, use: [:slugged, :history]

  belongs_to :organization, optional: true
  has_many :results_template_categories, -> { order(position: :asc) }, dependent: :destroy
  has_many :results_categories, through: :results_template_categories

  alias_attribute :categories, :results_categories

  scope :standard, -> { select('results_templates.*, count(results_categories.id) as category_count')
                            .joins(:results_categories).where(organization: nil).group(:id).order('category_count') }

  validates_presence_of :name, :aggregation_method

  def self.default
    find_by(slug: 'simple')
  end

  def dup_with_categories
    template = dup
    template.results_categories = results_categories.map(&:dup)
    template
  end
end
