class ResultsTemplate < ApplicationRecord
  include Auditable
  extend FriendlyId

  enum method: [:inclusive, :strict]
  friendly_id :name, use: [:slugged, :history]

  belongs_to :organization, optional: true
  has_many :results_template_categories
  has_many :results_categories, through: :results_template_categories

  validates_presence_of :name, :method

  def self.keys_and_names
    all.map { |template| [template.slug, template.name] }
  end
end
