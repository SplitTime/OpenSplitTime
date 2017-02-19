class Participant < ActiveRecord::Base
  PERMITTED_PARAMS = [:id, :city, :state_code, :country_code, :first_name, :last_name, :gender,
                      :email, :phone, :birthdate, :concealed]

  include Auditable
  include Concealable
  include PersonalInfo
  include Searchable
  include SetOperations
  include Matchable
  strip_attributes collapse_spaces: true
  enum gender: [:male, :female]
  has_many :connections, dependent: :destroy
  has_many :followers, through: :connections, source: :user
  has_many :efforts
  belongs_to :claimant, class_name: 'User', foreign_key: 'user_id'

  attr_accessor :suggested_match

  # Outer joins are required to find participants having no associated efforts
  scope :with_age_and_effort_count, -> { select(SQL[:age_and_effort_count])
                                             .joins('LEFT OUTER JOIN efforts ON (efforts.participant_id = participants.id)')
                                             .joins('LEFT OUTER JOIN events ON (events.id = efforts.event_id)')
                                             .group('participants.id') }
  scope :ordered_by_name, -> { order(:last_name, :first_name) }

  SQL = {age_and_effort_count: 'participants.*, COUNT(efforts.id) as effort_count, ROUND(AVG((extract(epoch from(current_date - events.start_time))/60/60/24/365.25) + efforts.age)) as participant_age',
         ages_from_events: '((extract(epoch from(current_date - events.start_time))/60/60/24/365.25) + efforts.age)'}

  validates_presence_of :first_name, :last_name, :gender
  validates :email, allow_blank: true, length: {maximum: 105},
            uniqueness: {case_sensitive: false},
            format: {with: VALID_EMAIL_REGEX}

  def self.search(param)
    return none if param.blank? || (param.length < 3)
    flexible_search(param)
  end

  def self.age_matches(age_param)
    return none unless age_param.is_a?(Numeric)
    threshold = 2 # Allow for some inaccuracy in reporting, rounding errors, etc.
    age_hash = approximate_ages_today.merge(exact_ages_today)
                   .reject { |_, age| (age - age_param).abs > threshold }
    self.where(id: age_hash.keys)
  end

  def self.columns_to_pull_from_model
    id = ['id']
    foreign_keys = Participant.column_names.find_all { |x| x.include?('_id') }
    stamps = Participant.column_names.find_all { |x| x.include?('_at') | x.include?('_by') }
    geographic = %w(country_code state_code city)
    (column_names - (id + foreign_keys + stamps + geographic)).map(&:to_sym)
  end

  def self.approximate_ages_today # Returns a hash of {participant_id => approximate age}
    joins(:efforts => :event).group('participants.id').average(SQL[:ages_from_events]).transform_values(&:to_f)
  end

  private_class_method :approximate_ages_today

  def approximate_age_today
    average = efforts.joins(:event).average(SQL[:ages_from_events]).to_f
    average == 0 ? nil : average
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

  # Methods related to matching and merging efforts with participants

  def most_likely_duplicate
    possible_matching_participants.first
  end

  def associate_effort(effort)
    if AttributePuller.pull_attributes!(self, effort)
      if effort.update(participant: self)
        logger.info "Effort #{effort.name} was associated with Participant #{self.name}"
        true
      else
        logger.info "Effort #{effort.name} could not be associated with Participant #{self.name}: " +
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
end