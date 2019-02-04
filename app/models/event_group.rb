# frozen_string_literal: true

class EventGroup < ApplicationRecord
  enum data_entry_grouping_strategy: [:ungrouped, :location_grouped]

  include Auditable
  include Concealable
  include Delegable
  include SplitAnalyzable
  extend FriendlyId

  strip_attributes collapse_spaces: true
  friendly_id :name, use: [:slugged, :history]
  has_many :events, dependent: :destroy
  has_many :efforts, through: :events
  has_many :raw_times, dependent: :destroy
  has_many :partners
  belongs_to :organization

  validates_presence_of :name, :organization_id
  validates_uniqueness_of :name, case_sensitive: false
  validates_with GroupedEventsValidator

  delegate :stewards, to: :organization
  delegate :start_time, :home_time_zone, :start_time_local, to: :first_event, allow_nil: true

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

  def multiple_events?
    events.many?
  end

  def multiple_laps?
    events.any?(&:multiple_laps?)
  end

  def multiple_sub_splits?
    events.any?(&:multiple_sub_splits?)
  end

  def permit_notifications?
    visible? && available_live?
  end

  def pick_partner_with_banner
    partners.with_banners.flat_map { |partner| [partner] * partner.weight }.shuffle.first
  end

  def single_lap?
    !multiple_laps?
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

  def not_expected_bibs(split_name)
    query = EventGroupQuery.not_expected_bibs(id, split_name)
    ActiveRecord::Base.connection.execute(query).values.flatten
  end

  private

  def split_analyzable
    self
  end
end
