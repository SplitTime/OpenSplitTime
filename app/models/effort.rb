class Effort < ApplicationRecord
  enum :data_status, [:bad, :questionable, :good] # nil = unknown, 0 = bad, 1 = questionable, 2 = good

  # See app/concerns/data_status_methods for related scopes and methods
  VALID_STATUSES = [nil, data_statuses[:good]].freeze

  include UrlAccessible
  include Matchable
  include TrimTimeAttributes
  include TimeZonable
  include Subscribable
  include StateCountrySyncable
  include Searchable
  include PersonalInfo
  include LapsRequiredMethods
  include GuaranteedFindable
  include DelegatedConcealable
  include Delegable
  include DataStatusMethods
  include CapitalizeAttributes
  include Auditable
  extend FriendlyId

  strip_attributes collapse_spaces: true
  strip_attributes only: [:phone, :emergency_phone], regex: /[^0-9|+]/
  capitalize_attributes :first_name, :last_name, :city, :emergency_contact
  friendly_id :slug_candidates, use: [:slugged, :history]
  trim_time_attributes :scheduled_start_time
  zonable_attributes :actual_start_time, :scheduled_start_time, :event_start_time, :calculated_start_time, :assumed_start_time
  has_paper_trail

  belongs_to :event, counter_cache: true, touch: true
  belongs_to :person, optional: true

  # effort_segments are destroyed when the associated split_times are destroyed.
  # This is accomplished by the :dependent option on the has_many :split_times association.
  # Do not add a dependent: :destroy option to the has_many :effort_segments association
  # because it will cause postgres to throw an error when an effort is destroyed.
  has_many :effort_segments
  has_many :split_times, dependent: :destroy, autosave: true
  has_many :notifications, dependent: :destroy
  has_one_attached :photo do |photo|
    photo.variant :thumbnail, resize_to_limit: [50, 50]
    photo.variant :small, resize_to_limit: [150, 150]
    photo.variant :medium, resize_to_limit: [500, 500]
  end

  accepts_nested_attributes_for :split_times, allow_destroy: true, reject_if: :reject_split_time?

  attr_accessor :over_under_due, :next_expected_split_time, :suggested_match, :points
  attr_writer :last_reported_split_time, :event_start_time, :template_age

  alias_attribute :participant_id, :person_id
  delegate :event_group, :events_within_group, to: :event
  delegate :organization, :concealed?, to: :event_group

  validates_presence_of :event, :first_name, :last_name, :gender
  validates :email, allow_blank: true, length: { maximum: 105 }, format: { with: VALID_EMAIL_REGEX }
  validates :phone, allow_blank: true, format: { with: VALID_PHONE_REGEX }
  validates :emergency_phone, allow_blank: true, format: { with: VALID_PHONE_REGEX }
  validates_with EffortAttributesValidator
  validates_with BirthdateValidator
  validates :photo,
            content_type: { in: %w[image/png image/jpeg], message: "must be a png or jpeg file" },
            size: { less_than: 1.megabyte, message: "must be less than 1 MB" }

  before_save :reset_age_from_birthdate
  after_save :set_performance_data
  after_touch :set_performance_data
  after_update_commit :broadcast_update

  pg_search_scope :search_bib, against: :bib_number, using: { tsearch: { any_word: true } }
  scope :bib_not_hardcoded, -> { where(bib_number_hardcoded: [false, nil]) }
  scope :bib_number_among, -> (param) { param.present? ? search_bib(param) : all }
  scope :on_course, -> (course) { includes(:event).where(events: { course_id: course.id }) }
  scope :unreconciled, -> { where(person_id: nil) }
  scope :finished, -> { where(finished: true) }
  scope :unfinished, -> { where(finished: [false, nil]) }
  scope :started, -> { where(started: true) }
  scope :unstarted, -> { where(started: [false, nil]) }
  scope :checked_in, -> { where(checked_in: true) }
  scope :photo_assigned, -> { joins("join active_storage_attachments asa on asa.record_type = 'Effort' and asa.name = 'photo' and asa.record_id = efforts.id") }
  scope :no_photo_assigned, -> { joins("left join active_storage_attachments asa on asa.record_type = 'Effort' and asa.name = 'photo' and asa.record_id = efforts.id").where("asa.id is null") }
  scope :finish_info_subquery, -> { from(EffortQuery.finish_info_subquery(self)) }
  scope :ranked_order, -> { order(overall_performance: :desc, bib_number: :asc) }
  scope :ranking_subquery, -> { from(EffortQuery.ranking_subquery(self)) }
  scope :roster_subquery, -> { from(EffortQuery.roster_subquery(self)) }
  scope :with_policy_scope_attributes, lambda {
    from(select("efforts.*, event_groups.organization_id, event_groups.concealed").joins(event: :event_group), :efforts)
  }

  def self.null_record
    @null_record ||= Effort.new(first_name: "", last_name: "")
  end

  def self.search(param)
    parser = SearchStringParser.new(param)
    names_locations_default_all(parser.word_component).bib_number_among(parser.number_component)
  end

  def to_s
    slug
  end

  def slug_candidates
    [[:event_name, :full_name], [:event_name, :full_name, :state_and_country], [:event_name, :full_name, :state_and_country, Date.today.to_s],
     [:event_name, :full_name, :state_and_country, Date.today.to_s, Time.current.strftime("%H:%M:%S")]]
  end

  def reject_split_time?(attributes)
    persisted = attributes[:id].present?
    time_values = attributes.slice(:time_from_start, :elapsed_time, :military_time, :absolute_time_local, :absolute_time).values
    without_time = time_values.all?(&:blank?)
    blank_time = without_time && time_values.any? { |value| value == "" }
    attributes.merge!(_destroy: true) if persisted && blank_time
    without_time && !persisted # reject new split_time if all time attributes are empty
  end

  def should_generate_new_friendly_id?
    slug.blank? || first_name_changed? || last_name_changed? || state_code_changed? || country_code_changed? || event&.short_name_changed? || event_group&.name_changed?
  end

  def actual_start_time
    return @actual_start_time if defined?(@actual_start_time)

    @actual_start_time = attributes.has_key?("actual_start_time") ? attributes["actual_start_time"] : starting_split_time&.absolute_time
  end

  def calculated_start_time
    actual_start_time || assumed_start_time
  end

  def assumed_start_time
    attributes["assumed_start_time"] || scheduled_start_time || event_start_time
  end

  def event_start_time
    @event_start_time ||= attributes["event_start_time"] || event&.scheduled_start_time
  end

  def home_time_zone
    @home_time_zone ||= attributes["home_time_zone"] || event&.home_time_zone
  end

  def scheduled_start_offset
    @scheduled_start_offset ||=
      begin
        return attributes["scheduled_start_offset"] if attributes.has_key?("scheduled_start_offset")

        (scheduled_start_time && event_start_time && scheduled_start_time - event_start_time) || 0
      end
  end

  def scheduled_start_offset=(seconds)
    return unless seconds.present? && event_start_time

    self.scheduled_start_time = event_start_time + seconds.to_i
  end

  def event_name
    @event_name ||= event&.name
  end

  def event_short_name
    @event_short_name ||= event&.short_name
  end

  def laps_required
    @laps_required ||= attributes["laps_required"] || event.laps_required
  end

  def last_reported_split_time
    @last_reported_split_time ||= ordered_split_times.last
  end

  def finish_split_time
    @finish_split_time ||= last_reported_split_time if finished?
  end

  def starting_split_time
    @starting_split_time ||= split_times.find(&:starting_split_time?)
  end

  def start_split_id
    return attributes["start_split_id"] if attributes.has_key?("start_split_id")

    event.start_split.id
  end

  def laps_finished
    return attributes["laps_finished"] if attributes["laps_finished"].present?

    last_split_time = last_reported_split_time
    return 0 unless last_split_time

    last_split_time.split.finish? ? last_split_time.lap : last_split_time.lap - 1
  end

  def laps_started
    attributes["laps_started"] || last_reported_split_time&.lap || 0
  end

  def has_start_time?
    split_times.find(&:start?).present?
  end

  def in_progress?
    started? && !stopped?
  end

  def finish_status
    case
    when !started?
      "Not yet started"
    when dropped?
      "DNF"
    when finished?
      if attributes.has_key?("final_elapsed_seconds")
        return TimeConversion.seconds_to_hms(attributes["final_elapsed_seconds"])
      end

      finish_split_time.formatted_time_hhmmss
    else
      "In progress"
    end
  end

  def total_time_in_aid
    @total_time_in_aid ||=
      ordered_split_times.select(&:absolute_time).group_by(&:split_id).inject(0) do |total, (_, group)|
        total + (group.last.absolute_time - group.first.absolute_time)
      end
  end

  def split_times_data
    @split_times_data ||= SplitTimeQuery.time_detail(scope: { efforts: { id: id } }, home_time_zone: home_time_zone)
  end

  def ordered_split_times(lap_split = nil)
    if lap_split
      split_times.select { |st| st.lap_split == lap_split }.sort_by(&:bitkey)
    elsif split_times.all?(&:imposed_order)
      split_times.sort_by(&:imposed_order)
    else
      split_times.sort_by { |st| [st.lap, st.distance_from_start_of_lap, st.bitkey] }
    end
  end

  def ordered_splits
    @ordered_splits ||= event.ordered_splits
  end

  def lap_splits
    @lap_splits ||= event.required_lap_splits.presence || event.lap_splits_through(laps_started)
  end

  # @return [Integer, nil]
  def overall_rank
    return attributes["overall_rank"] if attributes.has_key?("overall_rank")

    with_rank.attributes["overall_rank"]
  end

  # @return [Integer, nil]
  def gender_rank
    return attributes["gender_rank"] if attributes.has_key?("gender_rank")

    with_rank.attributes["gender_rank"]
  end

  def current_age_approximate
    return @current_age_approximate if defined?(@current_age_approximate)
    return unless age.present? && calculated_start_time.present?

    @current_age_approximate ||= age && ((Time.current - calculated_start_time) / 1.year + age).round
  end

  def unreconciled?
    person_id.nil?
  end

  def with_rank
    Effort.where(id: id).ranking_subquery.first
  end

  def template_age
    @template_age || age
  end

  def delete_effort_segments
    result = EffortSegment.delete_for_effort(self)
    raise ::ActiveRecord::Rollback unless result.cmd_status.start_with?("DELETE")
  end

  def set_effort_segments
    result = EffortSegment.set_for_effort(self)
    raise ::ActiveRecord::Rollback unless result.cmd_status.start_with?("INSERT")
  end

  # Methods related to stopped split_time

  # Uses a reverse sort in order to get the most recent stopped_here split_time
  # if more than one exists
  def stopped_split_time
    ordered_split_times.reverse.find(&:stopped_here)
  end

  private

  def broadcast_update
    broadcast_render_later_to event_group, partial: "efforts/updated", locals: { effort: self }
  end

  def generate_new_topic_resource?
    !finished? && progress_notifications_timely?
  end

  def progress_notifications_timely?
    calculated_start_time > 1.day.ago
  end

  def reset_age_from_birthdate
    return unless birthdate.present? && calculated_start_time.present?

    assign_attributes(age: ((event_start_time - birthdate.in_time_zone) / 1.year).to_i)
  end

  def set_performance_data
    ::Results::SetEffortPerformanceData.perform!(id)
  end
end
