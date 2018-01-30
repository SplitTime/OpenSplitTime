# frozen_string_literal: true

class EventGroup < ApplicationRecord
  include Auditable
  include Concealable
  include Delegable
  extend FriendlyId
  strip_attributes collapse_spaces: true
  friendly_id :name, use: [:slugged, :history]
  has_many :events
  belongs_to :organization
  validates_presence_of :name
  validates_uniqueness_of :name, case_sensitive: false

  delegate :stewards, to: :organization

  scope :standard_includes, -> { includes(events: :splits) }

  after_commit :align_available_live # Needed only so long as Event model retains duplicate available_live attribute

  def to_s
    name
  end

  def ordered_events
    events.sort_by { |event| [-event.start_time.to_i, event.name] }
  end

  def align_available_live
    events.each { |event| event.update(available_live: available_live) }
  end
end
