class Participant < ActiveRecord::Base #TODO: create class Person with subclasses Participant and Effort
  include PersonalInfo
  enum gender: [:male, :female]
  has_many :interests, dependent: :destroy
  has_many :users, :through => :interests
  has_many :efforts
  belongs_to :claimant, class_name: 'User', foreign_key: 'user_id'

  validates_presence_of :first_name, :last_name, :gender

  def approximate_age_today
    now = Time.now.utc.to_date
    return nil unless efforts.count > 0
    age_array = []
    efforts.each do |effort|
      if effort.age
        age_array << (years_between_dates(effort.event.first_start_time.to_date, now) + effort.age)
      end
    end
    age_array.count > 0 ? (age_array.inject(0.0) { |sum, el| sum + el } / age_array.size).to_i : nil
    # the inject statement avoids problems with integer division
  end

  def unclaimed?
    claimant.nil?
  end

  def claimed?
    !unclaimed?
  end

  def self.first_name_matches(param, rigor = 'soft')
    return matches('first_name', param) || none if rigor == 'soft'
    exact_matches('first_name', param) || none
  end

  def self.last_name_matches(param, rigor = 'soft')
    return matches('last_name', param) || none if rigor == 'soft'
    exact_matches('last_name', param) || none
  end

  def self.full_name_matches(param, participants, rigor = 'soft')
    matching_participants = []
    if rigor == 'soft'
      participants.each do |participant|
        if "%#{participant.full_name.strip.downcase}%" == "%#{param.strip.downcase}%"
          matching_participants << participant
        end
      end
    else
      participants.each do |participant|
        if participant.full_name.strip.downcase == param.strip.downcase
          matching_participants << participant
        end
      end
    end
    matching_participants
  end

  def self.gender_matches(param)
    gender_int = 1 if param == "female"
    gender_int = 1 if param == 1
    gender_int = 0 if param == "male"
    gender_int = 0 if param == 0
    where(gender: gender_int)
  end

  def self.country_matches(param)
    where(country_code: param) || none
  end

  def self.state_matches(param, rigor = 'exact')
    return matches('state_code', param) || none if rigor == 'soft'
    exact_matches('state_code', param) || none
  end

  def self.email_matches(param, rigor = 'exact')
    return matches('email', param) || none if rigor == 'soft'
    exact_matches('email', param) || none
  end

  def self.age_matches(param, participants, rigor = 'soft')
    return none unless param
    matching_participants = []
    threshold = rigor == 'exact' ? 1 : 2
    participants.each do |participant|
      age = participant.age_today
      return none unless age
      if (age - param).abs < threshold
        matching_participants << participant
      end
    end
    matching_participants
  end

  def self.matches(field_name, param)
    where("lower(#{field_name}) like ?", "%#{param}%")
  end

  def self.exact_matches(field_name, param)
    where("lower(#{field_name}) like ?", "#{param}")
  end

  def self.search(param)
    return Participant.none if param.blank?

    param.strip!.downcase!
    (first_name_matches(param) + last_name_matches(param) + email_matches(param)).uniq
  end

  def self.columns_to_pull_from_effort
    id = ["id"]
    foreign_keys = Participant.column_names.find_all { |x| x.include?("_id") }
    stamps = Participant.column_names.find_all { |x| x.include?("_at") | x.include?("_by") }
    (column_names - (id + foreign_keys + stamps)).map &:to_sym
  end

  def pull_data_from_effort(effort_id)
    @effort = Effort.find(effort_id)
    participant_attributes = Participant.columns_to_pull_from_effort
    participant_attributes.each do |attribute|
      assign_attributes({attribute => @effort[attribute]}) if self[attribute].blank?
    end
    if save
      @effort.participant ||= self
      @effort.save
    end
  end

end
