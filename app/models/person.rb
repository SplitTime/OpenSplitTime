class Person < ApplicationRecord

  include Auditable
  include Concealable
  include PersonalInfo
  include Searchable
  include SetOperations
  include Matchable
  extend FriendlyId
  friendly_id :slug_candidates, use: :slugged
  strip_attributes collapse_spaces: true
  strip_attributes only: [:phone], :regex => /[^0-9|+]/

  enum gender: [:male, :female]
  has_many :subscriptions, dependent: :destroy
  has_many :followers, through: :subscriptions, source: :user
  has_many :efforts
  belongs_to :claimant, class_name: 'User', foreign_key: 'user_id'

  attr_accessor :suggested_match

  # Outer joins are required to find people having no associated efforts
  scope :with_age_and_effort_count, -> { select(SQL[:age_and_effort_count])
                                             .joins('LEFT OUTER JOIN efforts ON (efforts.person_id = people.id)')
                                             .joins('LEFT OUTER JOIN events ON (events.id = efforts.event_id)')
                                             .group('people.id') }
  scope :ordered_by_name, -> { order(:last_name, :first_name) }

  SQL = {age_and_effort_count: 'people.*, COUNT(efforts.id) as effort_count, ' +
      'ROUND(AVG((extract(epoch from(current_date - events.start_time))/60/60/24/365.25) + efforts.age)) as current_age_from_efforts',
         ages_from_events: '((extract(epoch from(current_date - events.start_time))/60/60/24/365.25) + efforts.age)'}

  before_validation :set_topic_resource
  before_destroy :delete_topic_resource
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
    [:first_name, :last_name, :gender, :birthdate, :email, :phone, :photo_url, :created_by]
  end

  def to_s
    slug
  end

  def slug_candidates
    [:full_name, [:full_name, :state_and_country], [:full_name, :state_and_country, Date.today.to_s],
     [:full_name, :state_and_country, Date.today.to_s, Time.current.strftime('%H:%M:%S')]]
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
    efforts.all?(&:concealed?) # This avoids an n + 1 query when called from EventConcealedSetter
  end

  # Methods related to matching and merging efforts with people

  def most_likely_duplicate
    possible_matching_people.first
  end

  def associate_effort(effort)
    if AttributePuller.pull_attributes!(self, effort)
      if effort.update(person: self)
        logger.info "Effort #{effort.name} was associated with Person #{self.name}"
        true
      else
        logger.info "Effort #{effort.name} could not be associated with Person #{self.name}: " +
                        "#{effort.errors.full_messages}, #{self.errors.full_messages}"
        false
      end
    end
  end

  def merge_with(target)
    target.reload
    if AttributePuller.pull_attributes!(self, target)
      efforts << target.efforts
      target.destroy
    end
  end

  private

  def generate_new_topic_resource?
    topic_resource_key.nil? && slug.present?
  end
end
