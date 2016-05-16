class Participant < ActiveRecord::Base
  include Auditable
  include PersonalInfo
  include Searchable
  include SetOperations
  include Matchable
  enum gender: [:male, :female]
  has_many :interests, dependent: :destroy
  has_many :users, :through => :interests
  has_many :efforts
  belongs_to :claimant, class_name: 'User', foreign_key: 'user_id'

  attr_accessor :suggested_match

  scope :with_age_and_effort_count, -> { select("participants.*, COUNT(efforts.id) as effort_count, ROUND(AVG((extract(epoch from(current_date - events.first_start_time))/60/60/24/365.25) + efforts.age)) as participant_age")
                                             .joins("LEFT OUTER JOIN efforts ON (efforts.participant_id = participants.id)")
                                             .joins("INNER JOIN events ON (events.id = efforts.event_id)")
                                             .group("participants.id") }


  validates_presence_of :first_name, :last_name, :gender
  validates :email, allow_blank: true, length: {maximum: 105},
            uniqueness: {case_sensitive: false},
            format: {with: VALID_EMAIL_REGEX}


  # Search functions specific to Participant

  def self.search(param)
    return none if param.blank? || (param.length < 3)
    flexible_search(param)
  end

  def approximate_age_today
    efforts.joins(:event).average("((extract(epoch from(current_date - events.first_start_time))/60/60/24/365.25) + efforts.age)").to_f
  end

  def self.approximate_ages_today # Returns a hash of {participant_id => approximate age}
    raw_hash = joins(:efforts => :event)
                   .group(:participants)
                   .average("((extract(epoch from(current_date - events.first_start_time))/60/60/24/365.25) + efforts.age)")
    return_hash = {}
    raw_hash.each do |aggregate, value|
      participant_id = aggregate.split(',')[0].gsub(/[^0-9]/, '').to_i
      return_hash[participant_id] = value.to_f
    end
    return_hash
  end

  def self.age_matches(age_param, participants)
    return none unless age_param.is_a?(Numeric)
    exact_age_hash = participants.exact_ages_today
    approximate_age_hash = participants.approximate_ages_today
    participants.each do |participant|
      age = participant.age_today
      next unless age
      if (age - age_param).abs < threshold
        matches << participant
      end
    end
    matches
  end

  # Methods for determining if a user has claimed a participant

  def unclaimed?
    claimant.nil?
  end

  def claimed?
    claimant.present?
  end

  # Methods related to matching and merging efforts with participants

  def pull_data_from_effort(effort)
    resolve_country(effort)
    resolve_state_and_city(effort)
    participant_attributes = Participant.columns_to_pull_from_model
    participant_attributes.each do |attribute|
      assign_attributes({attribute => effort[attribute]}) if self[attribute].blank?
    end
    if save
      effort.participant ||= self
      effort.save
    end
  end

  def most_likely_duplicate
    possible_matching_participants.first
  end

  def merge_with(target)
    @target_participant = Participant.find(target.id)
    resolve_country(@target_participant)
    resolve_state_and_city(@target_participant)
    Participant.columns_to_pull_from_model.each do |attribute|
      assign_attributes({attribute => @target_participant[attribute]}) if self[attribute].blank?
    end
    if save
      efforts << @target_participant.efforts
      @target_participant.efforts = []
      @target_participant.destroy
    else
      flash[:danger] = "Participants could not be merged"
    end
  end

  def resolve_country(target)
    return if target.country_code.blank?
    if country_code.blank? &&
        (state_code.blank? |
            (state_code == target.state_code) |
            (Carmen::Country.coded(target.country_code).subregions.coded(state_code)))
      assign_attributes(country_code: target.country_code)
    end
  end

  def resolve_state_and_city(target)
    return if target.state_code.blank?
    if state_code.blank? &&
        (country_code.blank? |
            (country_code == target.country_code) |
            (Carmen::Country.coded(country_code).subregions.coded(target.state_code)))
      assign_attributes(state_code: target.state_code, city: target.city)
    elsif (state_code == target.state_code) && city.blank?
      assign_attributes(city: target.city)
    end
  end

  private

  def self.columns_to_pull_from_model
    id = ["id"]
    foreign_keys = Participant.column_names.find_all { |x| x.include?("_id") }
    stamps = Participant.column_names.find_all { |x| x.include?("_at") | x.include?("_by") }
    geographic = ["country_code", "state_code", "city"]
    (column_names - (id + foreign_keys + stamps + geographic)).map &:to_sym
  end

end
