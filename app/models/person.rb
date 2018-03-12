# frozen_string_literal: true

class Person < ApplicationRecord

  include Auditable
  include Concealable
  include PersonalInfo
  include Searchable
  include SetOperations
  include Matchable
  extend FriendlyId
  strip_attributes collapse_spaces: true
  strip_attributes only: [:phone], :regex => /[^0-9|+]/
  friendly_id :slug_candidates, use: [:slugged, :history]

  enum gender: [:male, :female]
  has_many :subscriptions, dependent: :destroy
  has_many :followers, through: :subscriptions, source: :user
  has_many :efforts
  belongs_to :claimant, class_name: 'User', foreign_key: 'user_id'
  has_attached_file :photo, styles: {medium: '640x480>', small: '320x240>', thumb: '160x120>'}, default_url: ':style/missing_person_photo.png'

  attr_accessor :suggested_match

  scope :with_age_and_effort_count, -> { select(SQL[:age_and_effort_count]).left_joins(efforts: :event).group('people.id') }
  scope :standard_includes, -> { includes(:efforts).with_age_and_effort_count }

  SQL = {age_and_effort_count: 'people.*, COUNT(efforts.id) as effort_count, ' +
      'ROUND(AVG((extract(epoch from(current_date - events.start_time))/60/60/24/365.25) + efforts.age)) ' +
      'as current_age_from_efforts'}

  before_validation :set_topic_resource
  before_destroy :delete_topic_resource
  validates_presence_of :first_name, :last_name, :gender
  validates :email, allow_blank: true, length: {maximum: 105},
            format: {with: VALID_EMAIL_REGEX}
  validates :phone, allow_blank: true, format: {with: VALID_PHONE_REGEX}
  validates_with BirthdateValidator
  validates_attachment :photo,
                       content_type: { content_type: %w(image/png image/jpeg)},
                       file_name: { matches: [/png\z/, /jpe?g\z/, /PNG\z/, /JPE?G\z/] },
                       size: { in: 0..2000.kilobytes }

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

  def set_topic_resource
    self.topic_resource_key = SnsTopicManager.generate(person: self) if generate_new_topic_resource?
  end

  def delete_topic_resource
    if topic_resource_key.present?
      SnsTopicManager.delete(person: self)
      self.topic_resource_key = nil
    end
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

  def add_follower(user)
    followers << user
  end

  def remove_follower(user)
    followers.delete(user)
  end

  def should_be_concealed?
    efforts.present? && efforts.all?(&:concealed?) # This avoids an n + 1 query when called from EventConcealedSetter
  end

  # Methods related to matching and merging efforts with people

  def most_likely_duplicate
    possible_matching_people.first
  end

  private

  def generate_new_topic_resource?
    topic_resource_key.nil? && slug.present?
  end
end
