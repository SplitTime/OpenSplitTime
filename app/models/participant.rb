class Participant < ActiveRecord::Base #TODO: create class Person with subclasses Participant and Effort
  include PersonalInfo
  include Searchable
  include Matchable
  enum gender: [:male, :female]
  has_many :interests, dependent: :destroy
  has_many :users, :through => :interests
  has_many :efforts
  belongs_to :claimant, class_name: 'User', foreign_key: 'user_id'

  validates_presence_of :first_name, :last_name, :gender

  # Search functions specific to Participant

  def approximate_age_today
    now = Time.now.utc.to_date
    return nil unless efforts.count > 0
    age_array = []
    efforts.includes(:event).each do |effort|
      if effort.age
        age_array << (years_between_dates(effort.event.first_start_time.to_date, now) + effort.age)
      end
    end
    age_array.mean
  end

  def self.age_matches(param, participants, rigor = 'soft')
    return none unless param
    matches = []
    threshold = rigor == 'exact' ? 1 : 2
    participants.each do |participant|
      age = participant.age_today
      next unless age
      if (age - param).abs < threshold
        matches << participant
      end
    end
    matches
  end

  def unclaimed?
    claimant.nil?
  end

  def claimed?
    !unclaimed?
  end


  def self.columns_to_pull_from_model
    id = ["id"]
    foreign_keys = Participant.column_names.find_all { |x| x.include?("_id") }
    stamps = Participant.column_names.find_all { |x| x.include?("_at") | x.include?("_by") }
    (column_names - (id + foreign_keys + stamps)).map &:to_sym
  end

  def pull_data_from_effort(effort_id)
    @effort = Effort.find(effort_id)
    participant_attributes = Participant.columns_to_pull_from_model
    participant_attributes.each do |attribute|
      assign_attributes({attribute => @effort[attribute]}) if self[attribute].blank?
    end
    if save
      @effort.participant ||= self
      @effort.save
    end
  end

  def most_likely_duplicate
    possible_duplicates.first
  end

  def possible_duplicates
    possible_matching_participants.reject { |x| x.id == self.id }
  end

  def merge_with(target)
    @target_participant = Participant.find(target.id)
    participant_attributes = Participant.columns_to_pull_from_model
    participant_attributes.each do |attribute|
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

end
