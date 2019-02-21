class EventSeries < ApplicationRecord
  include Delegable
  extend FriendlyId

  enum scoring_method: [:time, :rank, :points]
  friendly_id :name, use: [:slugged, :history]

  belongs_to :organization
  belongs_to :results_template
  has_many :events
  has_many :efforts, through: :events

  delegate :stewards, to: :organization

  validates_presence_of :name, :organization, :results_template, :scoring_method
  validate :point_system_present, if: :points?

  private

  def point_system_present
    if results_template.point_system.blank?
      errors.add(:base, 'Points scoring method is permitted only if the template has a point system')
    end
  end
end
