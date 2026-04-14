class Person < ApplicationRecord
  include UrlAccessible
  include Matchable
  include Subscribable
  include StateCountrySyncable
  include Searchable
  include PersonalInfo
  include Concealable
  include CapitalizeAttributes
  include Auditable
  extend FriendlyId

  strip_attributes collapse_spaces: true
  strip_attributes only: [:phone], regex: /[^0-9|+]/
  capitalize_attributes :first_name, :last_name, :city
  friendly_id :slug_candidates, use: [:slugged, :history]
  has_paper_trail

  has_many :efforts, dependent: :nullify
  has_many :historical_facts, dependent: :nullify
  has_many :lottery_entrants, dependent: :nullify
  belongs_to :claimant, class_name: "User", foreign_key: "user_id", optional: true
  has_one_attached :photo do |photo|
    photo.variant :thumbnail, resize_to_limit: [50, 50]
    photo.variant :small, resize_to_limit: [150, 150]
    photo.variant :medium, resize_to_limit: [500, 500]
  end

  attr_accessor :suggested_match

  scope :with_age_and_effort_count, lambda {
    from(select(SQL[:age_and_effort_count]).left_joins(efforts: :event).group("people.id"), :people)
  }
  scope :standard_includes, -> { includes(efforts: :person).with_age_and_effort_count }

  SQL = {
    age_and_effort_count: "people.*, COUNT(efforts.id) as effort_count, " \
                          "ROUND(AVG((extract(epoch from(current_date - events.scheduled_start_time))" \
                          "/60/60/24/365.25) + efforts.age)) " \
                          "as current_age_from_efforts"
  }.freeze

  validates :first_name, :last_name, :gender, presence: true
  validates :email, allow_blank: true, length: { maximum: 105 },
                    format: { with: VALID_EMAIL_REGEX }
  validates :phone, allow_blank: true, format: { with: VALID_PHONE_REGEX }
  validates :user_id, uniqueness: true, allow_blank: true
  validates_with BirthdateValidator

  after_update_commit :touch_related_events, if: :visibility_flags_changed?

  # This method needs to extract ids and run a new search to remain compatible
  # with the scope `.with_age_and_effort_count`.
  def self.search(param)
    return none unless param && param.size > 2

    search_names_and_locations(param)
  end

  def self.age_matches(age_param, threshold = 2)
    return none unless age_param

    ids = with_age_and_effort_count
          .select { |person| person.current_age && ((person.current_age - age_param).abs < threshold) }
          .map(&:id)
    where(id: ids)
  end

  def self.columns_to_pull_from_model
    [:first_name, :last_name, :gender, :birthdate, :email, :phone, :photo, :created_by]
  end

  def to_s
    slug
  end

  def slug_candidates
    [:full_name, [:full_name, :state_and_country], [:full_name, :state_and_country, Time.zone.today.to_s],
     [:full_name, :state_and_country, Time.zone.today.to_s, Time.current.strftime("%H:%M:%S")]]
  end

  def should_generate_new_friendly_id?
    slug.blank? || first_name_changed? || last_name_changed? || state_code_changed? || country_code_changed?
  end

  def current_age_approximate
    Person.where(id: id).with_age_and_effort_count.order(:id).first&.current_age_from_efforts
  end

  def current_age
    return nil if hide_age?

    super
  end

  def unclaimed?
    claimant.nil?
  end

  def claimed?
    claimant.present?
  end

  def most_likely_duplicate
    possible_matching_people.first
  end

  private

  # Invalidate cached public views (e.g. events/spread) that key on event.
  # Touch events directly rather than efforts because Effort#after_touch
  # triggers an expensive performance-data recalc we don't need here.
  def touch_related_events
    Event.where(id: efforts.select(:event_id)).touch_all
  end

  def visibility_flags_changed?
    saved_change_to_hide_age? || saved_change_to_obscure_name?
  end

  def generate_new_topic_resource?
    true
  end
end
