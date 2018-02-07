# frozen_string_literal: true

class EventGroup < ApplicationRecord
  include Auditable
  include Concealable
  include Delegable
  extend FriendlyId
  strip_attributes collapse_spaces: true
  friendly_id :name, use: [:slugged, :history]
  has_many :events
  has_many :live_times, through: :events
  belongs_to :organization
  validates_presence_of :name
  validates_uniqueness_of :name, case_sensitive: false

  delegate :stewards, to: :organization
  delegate :start_time, :start_time_in_home_zone, to: :first_event

  scope :standard_includes, -> { includes(events: :splits) }

  after_commit :align_available_live # Needed only so long as Event model retains duplicate available_live attribute

  def self.search(search_param)
    return all if search_param.blank?
    joins(:events).where('event_groups.name ILIKE ? OR events.name ILIKE ?', "%#{search_param}%", "%#{search_param}%")
  end

  def effort_count
    events.map(&:efforts).flatten.size
  end

  def to_s
    name
  end

  def ordered_events
    events.sort_by { |event| [event.start_time, event.name] }
  end

  def first_event
    ordered_events.first
  end

  def align_available_live
    events.each { |event| event.update(available_live: available_live) }
  end
end
