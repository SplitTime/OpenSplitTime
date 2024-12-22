# frozen_string_literal: true

class ResultsTemplate < ApplicationRecord
  extend FriendlyId

  enum aggregation_method: [:inclusive, :strict]
  friendly_id :name, use: [:slugged, :history]

  belongs_to :organization, optional: true
  has_many :template_categories, -> { order(position: :asc) }, dependent: :destroy, class_name: "ResultsTemplateCategory"
  has_many :categories, through: :template_categories, class_name: "ResultsCategory"

  scope :standard, lambda {
                     select("results_templates.*, count(results_categories.id) as category_count")
                         .joins(:categories).where(organization: nil).group(:id).order("category_count")
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
    template.categories = categories.map(&:dup)
    template
  end

  # @return [Boolean]
  def includes_nonbinary?
    categories.where(nonbinary: true).exists?
  end

  private

  def set_category_positions
    indexed_rtcs = template_categories.index_by(&:results_category_id)

    categories.each do |rc|
      rtc = indexed_rtcs[rc.id]
      rc.position = rtc.position
      rc.fixed_position = rtc.fixed_position
    end
  end
end
