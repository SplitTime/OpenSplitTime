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
  has_many :efforts, through: :events
  has_many :raw_times
  has_many :partners
  belongs_to :organization
  validates_presence_of :name
  validates_uniqueness_of :name, case_sensitive: false

  delegate :stewards, to: :organization
  delegate :start_time, :start_time_in_home_zone, to: :first_event
  delegate :ordered_split_names, :splits_by_event, to: :split_analyzer

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

  def multiple_laps?
    events.any?(&:multiple_laps?)
  end

  def permit_notifications?
    visible? && available_live?
  end

  def split_times
    SplitTime.joins(:effort).where(efforts: {event_id: events})
  end

  def visible?
    !concealed?
  end

  def split_and_effort_ids(split_name, bib_number)
    eg = EventGroup.select('splits.id as split_id, efforts.id as effort_id')
             .joins(events: [:splits, :efforts])
             .where(id: self, efforts: {bib_number: bib_number}, splits: {parameterized_base_name: split_name.parameterize})
             .first
    eg ? [eg.split_id, eg.effort_id] : []
  end

  private

  def split_analyzer
    EventGroupSplitAnalyzer.new(self)
  end
end
