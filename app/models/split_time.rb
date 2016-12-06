class SplitTime < ActiveRecord::Base
  enum data_status: [:bad, :questionable, :good, :confirmed]
  strip_attributes collapse_spaces: true

  VALID_STATUSES = [nil, data_statuses[:good], data_statuses[:confirmed]]

  include Auditable
  include DataStatusMethods
  belongs_to :effort
  belongs_to :split
  alias_attribute :bitkey, :sub_split_bitkey

  scope :ordered, -> { includes(:split).order('splits.distance_from_start, split_times.sub_split_bitkey') }
  scope :finish, -> { includes(:split).where(splits: {kind: Split.kinds[:finish]}) }
  scope :start, -> { includes(:split).where(splits: {kind: Split.kinds[:start]}) }
  scope :out, -> { where(sub_split_bitkey: SubSplit::OUT_BITKEY) }
  scope :in, -> { where(sub_split_bitkey: SubSplit::IN_BITKEY) }
  scope :within_time_range, -> (low_time, high_time) { where(time_from_start: low_time..high_time) }
  scope :basic_components, -> { select(:split_id, :sub_split_bitkey, :effort_id, :time_from_start) }
  scope :from_finished_efforts, -> { joins(:effort => {:split_times => :split}).where(splits: {kind: 1}) }

  attr_accessor :day_and_time_attr

  before_validation :delete_if_blank
  after_update :set_effort_data_status, if: :time_from_start_changed?

  validates_presence_of :effort_id, :split_id, :sub_split_bitkey, :time_from_start
  validates_uniqueness_of :split_id, scope: [:effort_id, :sub_split_bitkey],
                          message: 'only one of any given split/sub_split permitted within an effort'
  validate :course_is_consistent

  def self.confirmed!
    all.each { |resource| resource.confirmed! }
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

  def set_effort_data_status
    EffortDataStatusSetter.set_data_status(effort: effort)
  end

  def elapsed_time
    time_from_start && TimeConversion.seconds_to_hms(time_from_start)
  end

  alias_method :formatted_time_hhmmss, :elapsed_time

  def elapsed_time=(elapsed_time)
    self.time_from_start = TimeConversion.hms_to_seconds(elapsed_time)
  end

  def day_and_time
    @day_and_time ||= time_from_start && (event_start_time + effort_start_offset + time_from_start)
  end

  def day_and_time=(absolute_time)
    self.time_from_start = absolute_time.present? ?
        absolute_time - event_start_time - effort_start_offset : nil
  end

  def military_time
    day_and_time && TimeConversion.absolute_to_hms(day_and_time)
  end

  def military_time=(military_time, time_calculator = IntendedTimeCalculator)
    self.day_and_time = military_time.present? ?
        time_calculator.day_and_time(military_time: military_time, effort: effort, sub_split: sub_split) : nil
  end

  def split_name
    split.name(bitkey)
  end

  def effort_name
    effort.full_name
  end

  def event_name
    effort.event_name
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