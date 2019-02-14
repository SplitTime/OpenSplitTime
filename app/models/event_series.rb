class EventSeries < ApplicationRecord
  include Auditable
  extend FriendlyId

  friendly_id :name, use: [:slugged, :history]
  belongs_to :organization
  belongs_to :results_template
  has_many :events

  validates_presence_of :name, :organization, :results_template
end
