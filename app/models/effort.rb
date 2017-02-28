class Effort < ActiveRecord::Base
  enum data_status: [:bad, :questionable, :good] # nil = unknown, 0 = bad, 1 = questionable, 2 = good
  enum gender: [:male, :female]
  strip_attributes collapse_spaces: true

  # See app/concerns/data_status_methods for related scopes and methods
  VALID_STATUSES = [nil, data_statuses[:good]]
  PERMITTED_PARAMS = [:id, :event_id, :participant_id, :first_name, :last_name, :gender, :wave, :bib_number, :age, :birthdate,
                      :city, :state_code, :country_code, :start_time, :finished, :concealed, :start_time, :start_offset,
                      :beacon_url, :report_url, :photo_url, :phone, :email,
                      split_times_attributes: [*SplitTime::PERMITTED_PARAMS]]

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
  attr_writer :overall_place, :gender_place, :last_reported_split_time, :event_start_time

  validates_presence_of :event_id, :first_name, :last_name, :gender
  validates_uniqueness_of :participant_id, scope: :event_id, allow_blank: true
  validates_uniqueness_of :bib_number, scope: :event_id, allow_nil: true

  before_save :reset_age_from_birthdate

  scope :ordered_by_date, -> { includes(:event).order('events.start_time DESC') }
  scope :on_course, -> (course) { includes(:event).where(events: {course_id: course.id}) }
  scope :unreconciled, -> { where(participant_id: nil) }
  scope :started, -> { joins(:split_times).uniq }
  scope :with_ordered_split_times,
        -> { eager_load(:split_times).includes(split_times: :split)
                 .order('efforts.id, split_times.lap, splits.distance_from_start, split_times.sub_split_bitkey') }

  delegate :organization, to: :event

  def self.null_record
    @null_record ||= Effort.new(first_name: '', last_name: '')
  end

  def self.attributes_for_import
    id = ['id']
    foreign_keys = Effort.column_names.find_all { |x| x.include?('_id') }
    stamps = Effort.column_names.find_all { |x| x.include?('_at') | x.include?('_by') }
    (column_names - (id + foreign_keys + stamps)).map(&:to_sym)
  end

  def self.search(param)
    case
    when param.blank?
      all
    when param.numeric?
      where(bib_number: param.to_i)
    else
      flexible_search(param)
    end
  end

  def self.ranked_with_finish_status(args = {})
    return [] if EffortQuery.existing_scope_sql.blank?
    query = EffortQuery.rank_and_finish_status(effort_fields: (args[:effort_fields]),
                                               order_by: args[:order_by])
    self.find_by_sql(query)
  end

  def reset_age_from_birthdate
    assign_attributes(age: TimeDifference.between(birthdate, event_start_time).in_years.to_i) if birthdate.present?
  end

  def start_time
    event_start_time + start_offset
  end

  def start_time=(datetime)
    return unless datetime.present?
    new_datetime = datetime.is_a?(Hash) ? Time.zone.local(*datetime.values) : datetime
    self.start_offset = TimeDifference.from(event_start_time, new_datetime).in_seconds
  end

  def day_and_time(time_from_start)
    time_from_start && (start_time + time_from_start)
  end

  def event_start_time
    @event_start_time ||= attributes['event_start_time'].try(:in_time_zone) || event.start_time
  end

  def event_name
    @event_name ||= event.name
  end

  def laps_required
    attributes['laps_required'] || event.laps_required
  end

  def last_reported_split_time
    @last_reported_split_time ||= ordered_split_times.last
  end

  def valid_split_times
    @valid_split_times ||= split_times.valid_status.ordered
  end

  def finish_split_times
    @finish_split_times ||= split_times.finish.ordered
  end

  def start_split_times
    @start_split_times ||= split_times.start.ordered
  end

  def finish_split_time
    @finish_split_time ||= last_reported_split_time if finished?
  end

  def start_split_time
    start_split_times.first
  end

  def laps_finished
    return attributes['laps_finished'] if attributes['laps_finished'].present?
    last_split_time = last_reported_split_time
    return 0 unless last_split_time
    last_split_time.split.finish? ? last_split_time.lap : last_split_time.lap - 1
  end

  def laps_started
    attributes['laps_started'] || last_reported_split_time.try(:lap) || 0
  end

  # For an unlimited-lap (time-based) event, an effort is 'finished' when the person decides not to continue.
  # At that time, the stopped_here split_time is set, and the effort is considered to have finished.
  def finished?
    return attributes['finished'] if attributes.has_key?('finished')
    (laps_required.zero? ? split_times.any?(&:stopped_here) : (laps_finished >= laps_required))
  end

  def stopped?
    return attributes['stopped'] if attributes.has_key?('stopped')
    finished? || split_times.any?(&:stopped_here)
  end

  def started?
    return attributes['started'] if attributes.has_key?('started')
    split_times.present?
  end

  # For an unlimited-lap (time-based) event, nobody is considered to have 'dropped'
  # (the logic cannot return true for that type of event).
  def dropped?
    stopped? && !finished?
  end

  def in_progress?
    started? && !stopped?
  end

  def finish_status
    case
    when !started?
      'Not yet started'
    when dropped?
      'DNF'
    when finished?
      finish_split_time.formatted_time_hhmmss
    else
      'In progress'
    end
  end

  def time_in_aid(lap_split)
    time_array = ordered_split_times(lap_split).map(&:time_from_start)
    time_array.size > 1 ? time_array.last - time_array.first : nil
  end

  def total_time_in_aid
    @total_time_in_aid ||= ordered_split_times.group_by(&:split_id)
                               .inject(0) { |total, (_, group)| total + (group.last.time_from_start - group.first.time_from_start) }
  end

  def ordered_split_times(lap_split = nil)
    lap_split ? split_times.where(lap: lap_split.lap, split: lap_split.split)
                    .order(:sub_split_bitkey) : split_times.ordered
  end

  def ordered_splits
    @ordered_splits ||= event.ordered_splits
  end

  def lap_splits
    @lap_splits ||= event.required_lap_splits.presence || event.lap_splits_through(laps_started)
  end

  def overall_place
    (attributes['overall_rank'] || self.enriched.attributes['overall_rank']) if started?
  end

  def gender_place
    (attributes['gender_rank'] || self.enriched.attributes['overall_rank']) if started?
  end

  def approximate_age_today
    @approximate_age_today ||=
        age && (TimeDifference.from(event_start_time.to_date, Time.now.utc.to_date).in_years + age).to_i
  end

  def unreconciled?
    participant_id.nil?
  end

  def destroy_split_times(split_time_ids)
    stop_existed = stopped_split_time.present?
    split_times.where(id: split_time_ids).destroy_all
    set_data_status
    if stop_existed && stopped_split_time.blank?
      stop
    end
  end

  def set_data_status
    EffortDataStatusSetter.set_data_status(effort: self)
  end

  def enriched
    event.efforts.ranked_with_finish_status.find { |e| e.id == id }
  end

  def with_ordered_split_times
    Effort.where(id: id).with_ordered_split_times.first
  end

  # Methods related to stopped split_time

  # Uses a reverse sort in order to get the most recent stopped_here split_time
  # if more than one exists
  def stopped_split_time
    ordered_split_times.reverse.find(&:stopped_here)
  end

  def stopped_time_point
    stopped_split_time.try(:time_point)
  end

  def stop
    EffortStopper.stop(effort: self)
  end

  def unstop
    split_times.each do |split_time|
      split_time.stopped_here = false
      split_time.save if split_time.changed?
    end
  end
end