# frozen_string_literal: true

class Person < ApplicationRecord

  include Auditable, Concealable, PersonalInfo, Searchable, Subscribable, Matchable, UrlAccessible
  extend FriendlyId

  strip_attributes collapse_spaces: true
  strip_attributes only: [:phone], :regex => /[^0-9|+]/
  friendly_id :slug_candidates, use: [:slugged, :history]
  has_paper_trail

  enum gender: [:male, :female]
  has_many :efforts, dependent: :nullify
  belongs_to :claimant, class_name: 'User', foreign_key: 'user_id', optional: true
  has_one_attached :photo

  attr_accessor :suggested_match

  scope :with_age_and_effort_count, -> { select(SQL[:age_and_effort_count]).left_joins(efforts: :event).group('people.id') }
  scope :standard_includes, -> { includes(:efforts).with_age_and_effort_count }

  SQL = {age_and_effort_count: 'people.*, COUNT(efforts.id) as effort_count, ' +
      'ROUND(AVG((extract(epoch from(current_date - events.scheduled_start_time))/60/60/24/365.25) + efforts.age)) ' +
      'as current_age_from_efforts'}

  validates_presence_of :first_name, :last_name, :gender
  validates :email, allow_blank: true, length: {maximum: 105},
            format: {with: VALID_EMAIL_REGEX}
  validates :phone, allow_blank: true, format: {with: VALID_PHONE_REGEX}
  validates_with BirthdateValidator

  # This method needs to extract ids and run a new search to remain compatible
  # with the scope `.with_age_and_effort_count`.
  def self.search(param)
    return none unless param && param.size > 2
    parser = SearchStringParser.new(param)
    ids = country_state_name_search(parser).ids
    where(id: ids)
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
    [:full_name, [:full_name, :state_and_country], [:full_name, :state_and_country, Date.today.to_s],
     [:full_name, :state_and_country, Date.today.to_s, Time.current.strftime('%H:%M:%S')]]
  end

  def should_generate_new_friendly_id?
    slug.blank? || first_name_changed? || last_name_changed? || state_code_changed? || country_code_changed?
  end

  def current_age_approximate
    Person.where(id: id).with_age_and_effort_count.first&.current_age_from_efforts
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

  def generate_new_topic_resource?
    true
  end
end
