# frozen_string_literal: true

class Effort < ApplicationRecord
  enum data_status: [:bad, :questionable, :good] # nil = unknown, 0 = bad, 1 = questionable, 2 = good
  enum gender: [:male, :female]

  # See app/concerns/data_status_methods for related scopes and methods
  VALID_STATUSES = [nil, data_statuses[:good]].freeze

  include Auditable
  include DataStatusMethods
  include Delegable
  include GuaranteedFindable
  include LapsRequiredMethods
  include PersonalInfo
  include Searchable
  include Matchable
  extend FriendlyId
  strip_attributes collapse_spaces: true
  strip_attributes only: [:phone, :emergency_phone], :regex => /[^0-9|+]/
  friendly_id :slug_candidates, use: [:slugged, :history]
  belongs_to :event
  belongs_to :person
  has_many :split_times, dependent: :destroy
  has_attached_file :photo, styles: {medium: '640x480>', small: '320x240>', thumb: '160x120>'}, default_url: ':style/missing_person_photo.png'

  # Reject any new split_time hashes (having no :id) that don't have one of the attributes that will result in a time_from_start
  accepts_nested_attributes_for :split_times, allow_destroy: true, reject_if: :reject_split_time?

  attr_accessor :over_under_due, :next_expected_split_time, :suggested_match
  attr_writer :last_reported_split_time, :event_start_time

  alias_attribute :participant_id, :person_id
  delegate :event_group, :events_within_group, to: :event
  delegate :organization, :concealed?, to: :event_group
  delegate :stewards, to: :organization

  validates_presence_of :event_id, :first_name, :last_name, :gender, :start_offset
  validates :email, allow_blank: true, length: {maximum: 105}, format: {with: VALID_EMAIL_REGEX}
  validates :phone, allow_blank: true, format: {with: VALID_PHONE_REGEX}
  validates :emergency_phone, allow_blank: true, format: {with: VALID_PHONE_REGEX}
  validates_with EffortAttributesValidator
  validates_with BirthdateValidator
  validates_attachment :photo,
                       content_type: {content_type: %w(image/png image/jpeg)},
                       file_name: {matches: [/png\z/, /jpe?g\z/, /PNG\z/, /JPE?G\z/]},
                       size: {in: 0..2000.kilobytes}

  before_save :reset_age_from_birthdate

  pg_search_scope :search_bib, against: :bib_number, using: {tsearch: {any_word: true}}
  scope :bib_number_among, -> (param) { param.present? ? search_bib(param) : all }
  scope :on_course, -> (course) { includes(:event).where(events: {course_id: course.id}) }
  scope :unreconciled, -> { where(person_id: nil) }
  scope :started, -> { joins(:split_times).uniq }
  scope :unstarted, -> { includes(:split_times).where(split_times: {id: nil}) }
  scope :checked_in, -> { where(checked_in: true) }
  scope :ready_to_start, -> do
    select('efforts.*, splits.id as start_split_id')
        .without_start_time.checked_in
        .where("events.start_time + efforts.start_offset * interval '1 second' < ?", Time.now)
  end
  scope :concealed, -> { includes(event: :event_group).where(event_groups: {concealed: true}) }
  scope :visible, -> { includes(event: :event_group).where(event_groups: {concealed: false}) }
  scope :without_start_time, -> do
    joins(event: :course)
        .joins("INNER JOIN splits ON splits.course_id = courses.id AND splits.kind = 0")
        .joins("LEFT JOIN split_times ON split_times.effort_id = efforts.id AND split_times.lap = 1 AND split_times.split_id = splits.id")
        .where(split_times: {id: nil})
  end

  def self.null_record
    @null_record ||= Effort.new(first_name: '', last_name: '')
  end

  def self.attributes_for_import
    [:first_name, :last_name, :gender, :wave, :bib_number, :age, :birthdate, :city, :state_code, :country_code,
     :start_time, :start_offset, :beacon_url, :report_url, :photo, :phone, :email]
  end

  def self.search(param)
    return all unless param.present?
    parser = SearchStringParser.new(param)
    country_state_name_search(parser)
        .bib_number_among(parser.number_component)
  end

  def self.ranked_with_status(args = {})
    return [] if EffortQuery.existing_scope_sql.blank?
    query = EffortQuery.rank_and_status(args)
    self.find_by_sql(query)
  end

  def to_s
    slug
  end

  def slug_candidates
    [[:event_name, :full_name], [:event_name, :full_name, :state_and_country], [:event_name, :full_name, :state_and_country, Date.today.to_s],
     [:event_name, :full_name, :state_and_country, Date.today.to_s, Time.current.strftime('%H:%M:%S')]]
  end

  def reject_split_time?(attributes)
    persisted = attributes[:id].present?
    time_values = attributes.slice(:time_from_start, :elapsed_time, :military_time, :day_and_time).values
    without_time = time_values.all?(&:blank?)
    blank_time = without_time && time_values.any? { |value| value == '' }
    attributes.merge!(_destroy: true) if persisted and blank_time
    without_time && !persisted # reject new split_time if all time attributes are empty
  end

  def should_generate_new_friendly_id?
    slug.blank? || first_name_changed? || last_name_changed? || state_code_changed? || country_code_changed? || event&.name_changed?
  end

  def reset_age_from_birthdate
    assign_attributes(age: TimeDifference.between(birthdate, event_start_time).in_years.to_i) if birthdate.present?
  end

  def start_time
    event_start_time + start_offset
  end

  def start_time=(datetime)
    return unless datetime.present? && event.present?
    self.start_offset = TimeConversion.absolute_to_offset(datetime, event)
  end

  def day_and_time(time_from_start)
    time_from_start && (start_time + time_from_start)
  end

  def event_start_time
    @event_start_time ||= attributes['event_start_time']&.in_time_zone(event_home_zone) || event&.start_time_in_home_zone
  end

  def event_home_zone
    @event_home_zone ||= attributes['event_home_zone'] || event&.home_time_zone
  end

  def event_name
    @event_name ||= event&.name
  end

  def laps_required
    @laps_required ||= attributes['laps_required'] || event.laps_required
  end

  def last_reported_split_time
    @last_reported_split_time ||= ordered_split_times.last
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

  def start_split_id
    return attributes['start_split_id'] if attributes.has_key?('start_split_id')
    event.start_split.id
  end

  def laps_finished
    return attributes['laps_finished'] if attributes['laps_finished'].present?
    last_split_time = last_reported_split_time
    return 0 unless last_split_time
    last_split_time.split.finish? ? last_split_time.lap : last_split_time.lap - 1
  end

  def laps_started
    attributes['laps_started'] || last_reported_split_time&.lap || 0
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

  def has_start_time?
    split_times.find(&:start?).present?
  end

  # For an unlimited-lap (time-based) event, nobody is considered to have 'dropped'
  # (the logic cannot return true for that type of event).
  def dropped?
    stopped? && !finished?
  end

  def in_progress?
    started? && !stopped?
  end

  def beyond_start?
    return attributes['beyond_start'] if attributes.has_key?('beyond_start')
    split_times.find { |st| !st.start? || st.lap > 1 }.present?
  end

  def finish_status
    case
    when !started?
      'Not yet started'
    when dropped?
      'DNF'
    when finished?
      return TimeConversion.seconds_to_hms(attributes['final_time']) if attributes.has_key?('final_time')
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
    if lap_split
      split_times.select { |st| st.lap_split == lap_split }.sort_by(&:bitkey)
    elsif split_times.all?(&:imposed_order)
      split_times.sort_by(&:imposed_order)
    else
      split_times.sort_by { |st| [st.lap, st.distance_from_start, st.bitkey] }
    end
  end

  def ordered_splits
    @ordered_splits ||= event.ordered_splits
  end

  def lap_splits
    @lap_splits ||= event.required_lap_splits.presence || event.lap_splits_through(laps_started)
  end

  def overall_rank
    attributes['overall_rank'] || self.enriched.attributes['overall_rank']
  end

  def gender_rank
    attributes['gender_rank'] || self.enriched.attributes['overall_rank']
  end

  def current_age_approximate
    @current_age_approximate ||=
        age && (TimeDifference.from(event_start_time.to_date, Time.now.utc.to_date).in_years + age).to_i
  end

  def unreconciled?
    person_id.nil?
  end

  def set_data_status
    Interactors::UpdateEffortsStatus.perform!(self)
  end

  def enriched
    event.efforts.ranked_with_status.find { |e| e.id == id }
  end

  # Methods related to stopped split_time

  # Uses a reverse sort in order to get the most recent stopped_here split_time
  # if more than one exists
  def stopped_split_time
    ordered_split_times.reverse.find(&:stopped_here)
  end
end
