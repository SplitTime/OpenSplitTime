class Effort < ActiveRecord::Base
  enum data_status: [:bad, :questionable, :good] # nil = unknown, 0 = bad, 1 = questionable, 2 = good
  enum gender: [:male, :female]
  strip_attributes collapse_spaces: true

  # See app/concerns/data_status_methods for related scopes and methods
  VALID_STATUSES = [nil, data_statuses[:good]]

  include Auditable
  include Concealable
  include DataStatusMethods
  include GuaranteedFindable
  include PersonalInfo
  include Searchable
  include Matchable
  belongs_to :event
  belongs_to :participant
  has_many :split_times, dependent: :destroy
  accepts_nested_attributes_for :split_times, :reject_if => lambda { |s| s[:time_from_start].blank? && s[:elapsed_time].blank? }

  attr_accessor :over_under_due, :next_expected_split_time, :suggested_match, :segment_time
  attr_writer :overall_place, :gender_place, :last_reported_split_time

  validates_presence_of :event_id, :first_name, :last_name, :gender
  validates_uniqueness_of :participant_id, scope: :event_id, allow_blank: true
  validates_uniqueness_of :bib_number, scope: :event_id, allow_nil: true

  before_save :reset_age_from_birthdate

  scope :sorted_by_finish_time, -> { select('efforts.*, splits.kind, split_times.time_from_start as time')
                                         .finished.order('split_times.time_from_start') }
  scope :ordered_by_date, -> { includes(:event).order('events.start_time DESC') }
  scope :on_course, -> (course) { includes(:event).where(events: {course_id: course.id}) }
  scope :within_time_range, -> (low_time, high_time) { includes(:split_times => :split)
                                                           .where(splits: {kind: 1},
                                                                  split_times: {time_from_start: low_time..high_time}) }
  scope :unreconciled, -> { where(participant_id: nil) }
  scope :finished, -> { joins(:split_times => :split).where(splits: {kind: 1}) }

  delegate :race, to: :event

  def self.null_record
    @null_record ||= Effort.new(first_name: '', last_name: '')
  end

  def self.attributes_for_import
    id = ['id']
    foreign_keys = Effort.column_names.find_all { |x| x.include?('_id') }
    stamps = Effort.column_names.find_all { |x| x.include?('_at') | x.include?('_by') }
    (column_names - (id + foreign_keys + stamps)).map &:to_sym
  end

  def self.search(param)
    return all if param.blank?
    return where(bib_number: param.to_i) if param.to_i > 0
    flexible_search(param)
  end

  def reset_age_from_birthdate
    assign_attributes(age: TimeDifference.between(birthdate, event_start_time).in_years.to_i) if birthdate.present?
  end

  def start_time
    @start_time ||= event_start_time + start_offset
  end

  def start_time=(datetime)
    return unless datetime.present?
    new_datetime = datetime.is_a?(Hash) ? Time.zone.local(*datetime.values) : datetime
    TimeDifference.from(new_datetime, event_start_time).in_seconds
  end

  def event_start_time
    @event_start_time ||= event.start_time
  end

  def event_name
    @event_name ||= event.name
  end

  def last_reported_split_time
    @last_reported_split_time ||= ordered_split_times.last
  end

  def valid_split_times
    @valid_split_times ||= split_times.valid_status.ordered
  end

  def finished?
    finish_split_time.present?
  end

  def in_progress?
    dropped_split_id.nil? && finish_split_time.nil?
  end

  def dropped?
    dropped_split_id.present?
  end

  def started?
    split_times.present?
  end

  def finish_status
    return 'DNF' if dropped?
    return 'Not yet started' unless started?
    split_time = finish_split_time
    return split_time.formatted_time_hhmmss if split_time
    'In progress'
  end

  def finish_split_time
    @finish_split_time ||= split_times.finish.first
  end

  def start_split_time
    @start_split_time ||= split_times.start.first
  end

  def time_in_aid(split)
    time_array = ordered_split_times(split).map(&:time_from_start)
    time_array.size > 1 ? time_array.last - time_array.first : nil
  end

  def total_time_in_aid
    @total_time_in_aid ||= ordered_split_times.group_by(&:split_id)
                               .inject(0) { |total, (_, group)| total + (group.last.time_from_start - group.first.time_from_start) }
  end

  def ordered_splits
    @ordered_splits ||= event.ordered_splits
  end

  def ordered_split_times(split = nil)
    split ? split_times.where(split: split).order(:sub_split_bitkey) : split_times.ordered
  end

  def combined_places
    @combined_places ||= event.combined_places(self)
  end

  def overall_place
    @overall_place ||= event.overall_place(self)
  end

  def gender_place
    @gender_place ||= event.gender_place(self)
  end

  def approximate_age_today
    @approximate_age_today ||=
        age && (TimeDifference.from(event_start_time.to_date, Time.now.utc.to_date).in_years + age).to_i
  end

  def unreconciled?
    participant_id.nil?
  end

  def self.sorted_with_finish_status
    sorted_efforts = select('DISTINCT ON(efforts.id) efforts.*, splits.id as final_split_id, splits.base_name as final_split_name, splits.distance_from_start, split_times.time_from_start, split_times.sub_split_bitkey')
                         .joins(:split_times => :split)
                         .order('efforts.id, splits.distance_from_start DESC, split_times.sub_split_bitkey DESC')
                         .sort_by { |row| [row.dropped_split_id ? 1 : 0, -row.distance_from_start, row.time_from_start, row.gender, row.age ? -row.age : 0] }
    sorted_efforts.each_with_index do |effort, i|
      effort.overall_place = i + 1
      effort.gender_place = sorted_efforts[0..i].count { |e| e.gender == effort.gender }
    end
    sorted_efforts
  end

  def set_dropped_split_id
    dropped_split_id = find_dropped_split_id
    update(dropped_split_id: dropped_split_id)
    dropped_split_id
  end

  def find_dropped_split_id
    unless finish_split_time
      split_times.joins(:split).joins(:effort).order('efforts.id, splits.distance_from_start DESC').first.split_id
    end
  end
end