class ResultsTemplate < ApplicationRecord
  include Auditable
  extend FriendlyId

  enum aggregation_method: [:inclusive, :strict]
  friendly_id :name, use: [:slugged, :history]

  belongs_to :organization, optional: true
  has_many :results_template_categories, -> { order(position: :asc) }
  has_many :results_categories, through: :results_template_categories

  validates_presence_of :name, :aggregation_method
end
