# frozen_string_literal: true

class SplitTime < ApplicationRecord
  enum data_status: [:bad, :questionable, :good, :confirmed]
  strip_attributes collapse_spaces: true

  # See app/concerns/data_status_methods for related scopes and methods
  VALID_STATUSES = [nil, data_statuses[:good], data_statuses[:confirmed]]

  include Auditable
  include DataStatusMethods
  include GuaranteedFindable
  include TimePointMethods
  include TimeZonable

  zonable_attributes :absolute_time, :absolute_estimate_early, :absolute_estimate_late
  belongs_to :effort
  belongs_to :split
  has_many :raw_times, dependent: :nullify
  alias_attribute :bitkey, :sub_split_bitkey
  alias_attribute :with_pacer, :pacer
  attr_accessor :imposed_order, :segment_time, :time_exists
  attribute :absolute_estimate_early, :datetime
  attribute :absolute_estimate_late, :datetime
  attribute :matching_raw_time_id, :integer

  scope :ordered, -> { joins(:split).order('split_times.effort_id, split_times.lap, splits.distance_from_start, split_times.sub_split_bitkey') }
  scope :finish, -> { includes(:split).where(splits: {kind: Split.kinds[:finish]}) }
  scope :start, -> { includes(:split).where(splits: {kind: Split.kinds[:start]}) }
  scope :out, -> { where(sub_split_bitkey: SubSplit::OUT_BITKEY) }
  scope :in, -> { where(sub_split_bitkey: SubSplit::IN_BITKEY) }
  scope :with_time_from_start, -> do
    select('split_times.*, extract(epoch from split_times.absolute_time - sst.absolute_time) as time_from_start')
        .joins(SplitTimeQuery.starting_split_times(scope: {efforts: {id: current_scope.map(&:effort_id).uniq}}))
  end
  scope :visible, -> { includes(effort: {event: :event_group}).where('event_groups.concealed = ?', 'f') }
  scope :with_time_record_matchers, -> { joins(effort: {event: :event_group}).select("split_times.*, event_groups.home_time_zone, efforts.bib_number::text as bib_number") }

  # SplitTime::recorded_at_aid functions properly only when called on split_times within an event
  # Otherwise it includes split_times from aid_stations other than the given parameter

  scope :recorded_at_aid, -> (aid_station_id) { includes(split: :aid_stations).includes(:effort)
                                                    .where(aid_stations: {id: aid_station_id}) }

  before_validation :destroy_if_blank
  before_update :set_matching_raw_time, if: :matching_raw_time_id_changed?

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

  delegate :event_group, to: :effort

  def to_s
    "#{effort || '[unknown effort]'} at #{split || '[unknown split]'}"
  end

  def course_is_consistent
    if effort&.event && split && (effort.event.course_id != split.course_id)
      errors.add(:effort_id, 'the effort.event.course_id does not resolve with the split.course_id')
      errors.add(:split_id, 'the effort.event.course_id does not resolve with the split.course_id')
    end
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
    start_time = effort_starting_split_time&.absolute_time
    return nil unless start_time
    absolute_time - start_time
  end

  def time_from_start=(seconds)
    return if starting_split_time?
    start_time = effort_starting_split_time&.absolute_time
    return unless start_time
    self.absolute_time = seconds ? start_time + seconds : nil
  end

  def military_time
    absolute_time_local && TimeConversion.absolute_to_hms(absolute_time_local)
  end

  def military_time=(military_time)
    @military_time = military_time
    self.absolute_time = military_time.present? && effort.present? ?
                             IntendedTimeCalculator.absolute_time_local(military_time: military_time, effort: effort, time_point: time_point) : nil
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

  def event_group_id
    @event_group_id ||= event_group&.id
  end

  def start?
    !!split&.start?
  end

  def starting_split_time?
    self.start? && lap == 1
  end

  private

  def home_time_zone
    @home_time_zone ||= attributes['home_time_zone'] || effort.home_time_zone
  end

  def effort_starting_split_time
    effort.starting_split_time
  end

  def destroy_if_blank
    self.destroy if elapsed_time == ''
  end

  def set_matching_raw_time
    SplitTimes::MatchToRawTime.perform!(self, matching_raw_time_id)
    raise ActiveRecord::Rollback if errors.present?
  end
end
