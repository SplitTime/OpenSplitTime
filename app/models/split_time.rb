# frozen_string_literal: true

class SplitTime < ApplicationRecord
  enum data_status: [:bad, :questionable, :good, :confirmed]
  strip_attributes collapse_spaces: true

  # See app/concerns/data_status_methods for related scopes and methods
  VALID_STATUSES = [nil, data_statuses[:good], data_statuses[:confirmed]]

  include Auditable
  include DataStatusMethods
  include GuaranteedFindable
  belongs_to :effort
  belongs_to :split
  has_many :raw_times, dependent: :nullify
  alias_attribute :bitkey, :sub_split_bitkey
  alias_attribute :with_pacer, :pacer
  attr_accessor :raw_time_id, :time_exists, :imposed_order, :segment_time
  attribute :absolute_estimate_early, :datetime
  attribute :absolute_estimate_late, :datetime
  attribute :projected, :boolean

  scope :ordered, -> { joins(:split).order('split_times.effort_id, split_times.lap, splits.distance_from_start, split_times.sub_split_bitkey') }
  scope :int_and_finish, -> { includes(:split).where(splits: {kind: [Split.kinds[:intermediate], Split.kinds[:finish]]}) }
  scope :intermediate, -> { includes(:split).where(splits: {kind: Split.kinds[:intermediate]}) }
  scope :finish, -> { includes(:split).where(splits: {kind: Split.kinds[:finish]}) }
  scope :start, -> { includes(:split).where(splits: {kind: Split.kinds[:start]}) }
  scope :out, -> { where(sub_split_bitkey: SubSplit::OUT_BITKEY) }
  scope :in, -> { where(sub_split_bitkey: SubSplit::IN_BITKEY) }
  scope :with_time_from_start, -> do
    select('split_times.*, extract(epoch from split_times.absolute_time - sst.absolute_time) as time_from_start')
        .joins(SplitTimeQuery.starting_split_times(scope: {efforts: {id: current_scope.map(&:effort_id).uniq}}))
  end
  scope :visible, -> { includes(effort: {event: :event_group}).where('event_groups.concealed = ?', 'f') }
  scope :with_time_record_matchers, -> { joins(effort: :event).select("split_times.*, events.home_time_zone, efforts.bib_number::text as bib_number") }

  # SplitTime::recorded_at_aid functions properly only when called on split_times within an event
  # Otherwise it includes split_times from aid_stations other than the given parameter

  scope :recorded_at_aid, -> (aid_station_id) { includes(split: :aid_stations).includes(:effort)
                                                    .where(aid_stations: {id: aid_station_id}) }

  before_validation :destroy_if_blank

  validates_presence_of :effort, :split, :sub_split_bitkey, :absolute_time, :lap
  validates_uniqueness_of :split_id, scope: [:effort_id, :sub_split_bitkey, :lap],
                          message: 'only one of any given time_point permitted within an effort'
  validate :course_is_consistent

  def self.null_record
    @null_record ||= SplitTime.new
  end

  def self.confirmed!
    all.each { |resource| resource.confirmed! }
  end

  def self.effort_times(args)
    query = SplitTimeQuery.effort_times(args)
    ActiveRecord::Base.connection.execute(query).values.to_h
  end

  def self.with_time_point_rank
    return [] if SplitTimeQuery.existing_scope_sql.blank?
    query = SplitTimeQuery.with_time_point_rank
    self.find_by_sql(query)
  end

  def to_s
    "#{effort || '[unknown effort]'} at #{split || '[unknown split]'}"
  end

  def course_is_consistent
    if effort&.event && split && (effort.event.course_id != split.course_id)
      errors.add(:effort_id, 'the effort.event.course_id does not resolve with the split.course_id')
      errors.add(:split_id, 'the effort.event.course_id does not resolve with the split.course_id')
    end
  end

  def sub_split
    {split_id => bitkey}
  end

  def sub_split=(sub_split)
    self.split_id = sub_split.split_id
    self.bitkey = sub_split.bitkey
  end

  def sub_split_kind
    SubSplit.kind(bitkey)
  end

  def time_point
    TimePoint.new(lap, split_id, bitkey)
  end

  def time_point=(time_point)
    self.split_id = time_point.split_id
    self.bitkey = time_point.bitkey
    self.lap = time_point.lap
  end

  def lap_split
    LapSplit.new(lap, split)
  end

  def lap_split_key
    LapSplitKey.new(lap, split_id)
  end

  def effort_lap_key
    EffortLapKey.new(effort_id, lap)
  end

  def distance_from_start_of_lap
    split.distance_from_start
  end

  def total_distance
    lap_split.distance_from_start
  end

  def elapsed_time(options = {})
    return nil unless time_from_start
    seconds = options[:with_fractionals] ? time_from_start : time_from_start.round(0)
    TimeConversion.seconds_to_hms(seconds)
  end

  alias_method :formatted_time_hhmmss, :elapsed_time

  def elapsed_time=(elapsed_time)
    self.time_from_start = TimeConversion.hms_to_seconds(elapsed_time)
  end

  def time_from_start
    return attributes['time_from_start'] if attributes.has_key?('time_from_start')
    return nil unless absolute_time
    return 0 if starting_split_time?
    start_time = effort_start_split_time&.absolute_time
    return nil unless start_time
    absolute_time - start_time
  end

  def time_from_start=(seconds)
    return if starting_split_time?
    start_time = effort_start_split_time&.absolute_time
    return unless start_time
    self.absolute_time = seconds ? start_time + seconds : nil
  end

  def day_and_time
    @day_and_time ||= absolute_time&.in_time_zone(home_time_zone)
  end

  def day_and_time=(date_with_time)
    time_string = date_with_time.to_s
    self.absolute_time = ActiveSupport::TimeZone.new(home_time_zone).parse(time_string)
  end

  def military_time
    day_and_time && TimeConversion.absolute_to_hms(day_and_time)
  end

  def military_time=(military_time)
    @military_time = military_time
    self.day_and_time = military_time.present? && effort.present? ?
                            IntendedTimeCalculator.day_and_time(military_time: military_time, effort: effort, time_point: time_point) : nil
  end

  def name
    "#{effort_name}: #{split_name}"
  end

  def base_name
    @base_name ||= attributes['base_name'] || split.base_name
  end

  def split_name
    split&.name(bitkey) || '[unknown split]'
  end

  def split_name_with_lap
    @split_name_with_lap ||= split_name + (lap ? " Lap #{lap}" : ' [unknown lap]')
  end

  def extension
    SubSplit.kind(bitkey)
  end

  def bib_number
    @bib_number ||= attributes['bib_number'] || effort.bib_number
  end

  def effort_name
    @effort_name ||= effort&.full_name || '[unknown effort]'
  end

  def event_name
    @event_name ||= effort&.event_name || '[unknown event]'
  end

  def start?
    !!split&.start?
  end

  def starting_split_time?
    self.start? && lap == 1
  end

  private

  def event_start_time
    @event_start_time ||= effort.event_start_time
  end

  def home_time_zone
    @home_time_zone ||= attributes['home_time_zone'] || effort.home_time_zone
  end

  def effort_start_split_time
    effort.start_split_time
  end

  def destroy_if_blank
    self.destroy if elapsed_time == ''
  end
end
