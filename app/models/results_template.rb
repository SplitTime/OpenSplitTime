# frozen_string_literal: true

class ResultsTemplate < ApplicationRecord
  extend FriendlyId

  enum aggregation_method: [:inclusive, :strict]
  friendly_id :name, use: [:slugged, :history]

  belongs_to :organization, optional: true
  has_many :results_template_categories, -> { order(position: :asc) }, dependent: :destroy
  has_many :results_categories, through: :results_template_categories

  alias_method :categories, :results_categories

  scope :standard, lambda {
                     select("results_templates.*, count(results_categories.id) as category_count")
                         .joins(:results_categories).where(organization: nil).group(:id).order("category_count")
                   }

  validates_presence_of :name, :aggregation_method

  # @return [ResultsTemplate]
  def self.default
    find_by(slug: "simple")
  end

  # @return [ResultsTemplate]
  def dup_with_categories
    # This must be done first or relations will be lost
    set_category_positions

    template = dup
    template.results_categories = results_categories.map(&:dup)
    template
  end

  # @return [Boolean]
  def includes_nonbinary?
    results_categories.where(nonbinary: true).exists?
  end

  private

  def set_category_positions
    indexed_rtcs = results_template_categories.index_by(&:results_category_id)

    results_categories.each do |rc|
      rtc = indexed_rtcs[rc.id]
      rc.position = rtc.position
      rc.fixed_position = rtc.fixed_position
    end
  end
end
