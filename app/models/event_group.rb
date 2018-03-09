# frozen_string_literal: true

class EventGroup < ApplicationRecord
  enum data_entry_grouping_strategy: [:ungrouped, :location_grouped]

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

  def self.search(search_param)
    return all if search_param.blank?
    joins(:events).where('event_groups.name ILIKE ? OR events.name ILIKE ?', "%#{search_param}%", "%#{search_param}%")
  end

  def effort_count
    events.flat_map(&:efforts).size
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
end
