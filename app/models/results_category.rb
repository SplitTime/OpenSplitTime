class ResultsCategory < ApplicationRecord
  include Auditable
  extend FriendlyId

  INF = 1.0/0

  friendly_id :name, use: [:slugged, :history]

  belongs_to :organization, optional: true
  has_many :results_template_categories
  has_many :results_templates, through: :results_template_categories

  validates_presence_of :name

  def age_range
    (low_age || 0)..(high_age || INF)
  end

  def all_ages?
    age_range == (0..INF)
  end

  def all_genders?
    male? && female?
  end
end
