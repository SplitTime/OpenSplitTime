class SplitTime < ActiveRecord::Base
  enum data_status: [:bad, :questionable, :good, :confirmed]
  strip_attributes collapse_spaces: true

  # See app/concerns/data_status_methods for related scopes and methods
  VALID_STATUSES = [nil, data_statuses[:good], data_statuses[:confirmed]]

  include Auditable
  include Concealable
  include DataStatusMethods
  include GuaranteedFindable
  include Structpluck
  belongs_to :effort
  belongs_to :split
  has_many :live_times, dependent: :nullify
  alias_attribute :bitkey, :sub_split_bitkey

  scope :ordered, -> { joins(:split).order('split_times.lap, splits.distance_from_start, split_times.sub_split_bitkey') }
  scope :int_and_finish, -> { includes(:split).where(splits: {kind: [Split.kinds[:intermediate], Split.kinds[:finish]]}) }
  scope :intermediate, -> { includes(:split).where(splits: {kind: Split.kinds[:intermediate]}) }
  scope :finish, -> { includes(:split).where(splits: {kind: Split.kinds[:finish]}) }
  scope :start, -> { includes(:split).where(splits: {kind: Split.kinds[:start]}) }
  scope :out, -> { where(sub_split_bitkey: SubSplit::OUT_BITKEY) }
  scope :in, -> { where(sub_split_bitkey: SubSplit::IN_BITKEY) }
  scope :within_time_range, -> (low_time, high_time) { where(time_from_start: low_time..high_time) }
  scope :from_finished_efforts, -> { joins(effort: {split_times: :split}).where(splits: {kind: 1}) }

  # SplitTime::recorded_at_aid functions properly only when called on split_times within an event
  # Otherwise it includes split_times from aid_stations other than the given parameter

  scope :recorded_at_aid, -> (aid_station_id) { includes(split: :aid_stations).includes(:effort)
                                                    .where(aid_stations: {id: aid_station_id}) }

  before_validation :delete_if_blank

  validates_presence_of :effort_id, :split_id, :sub_split_bitkey, :time_from_start, :lap
  validates_uniqueness_of :split_id, scope: [:effort_id, :sub_split_bitkey, :lap],
                          message: 'only one of any given time_point permitted within an effort'
  validates :time_from_start, numericality: {greater_than_or_equal_to: 0}
  validate :course_is_consistent

  def self.null_record
    @null_record ||= SplitTime.new
  end

  def self.confirmed!
    all.each { |resource| resource.confirmed! }
  end

  def self.with_time_point_rank(split_time_fields: '*')
    return [] if SplitTimeQuery.existing_scope_sql.blank?
    query = SplitTimeQuery.with_time_point_rank(split_time_fields: split_time_fields)
    self.find_by_sql(query)
  end

  def to_s
    "#{effort.slug} at #{split.slug}"
  end

  def course_is_consistent
    if effort && effort.event && split && (effort.event.course_id != split.course_id)
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

  def time_point
    TimePoint.new(lap, split_id, bitkey)
  end

  def time_point=(time_point)
    self.split_id = time_point.split_id
    self.bitkey = time_point.bitkey
    self.lap = time_point.lap
  end

  def lap_split_key
    LapSplitKey.new(lap, split_id)
  end

  def effort_lap_key
    EffortLapKey.new(effort_id, lap)
  end

  def set_effort_data_status
    effort.set_data_status
  end

  def elapsed_time(options = {})
    return nil unless time_from_start
    time = options[:with_fractionals] ? time_from_start : time_from_start.round(0)
    TimeConversion.seconds_to_hms(time)
  end

  alias_method :formatted_time_hhmmss, :elapsed_time

  def elapsed_time=(elapsed_time)
    self.time_from_start = TimeConversion.hms_to_seconds(elapsed_time)
  end

  def day_and_time
    @day_and_time ||= attributes['day_and_time'].try(:in_time_zone) ||
        time_from_start && (event_start_time + effort_start_offset + time_from_start)
  end

  def day_and_time=(absolute_time)
    self.time_from_start = absolute_time.present? ?
        absolute_time - event_start_time - effort_start_offset : nil
  end

  def military_time
    day_and_time && TimeConversion.absolute_to_hms(day_and_time)
  end

  def military_time=(military_time)
    self.day_and_time = military_time.present? ?
        IntendedTimeCalculator.day_and_time(military_time: military_time, effort: effort, time_point: time_point) : nil
  end

  def name
    "#{effort_name}: #{split_name}"
  end

  def base_name
    @base_name ||= attributes['base_name'] || split.base_name
  end

  def split_name
    split ? split.name(bitkey) : '[unknown split]'
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
    @effort_name ||= effort ? effort.full_name : '[unknown effort]'
  end

  def event_name
    @event_name ||= effort ? effort.event_name : '[unknown event]'
  end

  private

  def event_start_time
    @event_start_time ||= effort.event_start_time
  end

  def effort_start_offset
    @effort_start_offset ||= effort.start_offset
  end

  def delete_if_blank
    self.delete if elapsed_time == ''
  end
end
