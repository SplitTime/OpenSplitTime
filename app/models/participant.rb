class Participant < ActiveRecord::Base #TODO: create class Person with subclasses Participant and Effort
  enum gender: [:male, :female]
  has_many :interests, dependent: :destroy
  has_many :users, :through => :interests
  has_many :efforts
  belongs_to :claimant, class_name: 'User', foreign_key: 'user_id'

  validates_presence_of :first_name, :last_name, :gender

  def full_name
    first_name + " " + last_name
  end

  def bio
    approximate_age.nil? ? gender.titlecase : "#{gender.titlecase}, #{approximate_age}"
  end

  def approximate_age
    now = Time.now.utc.to_date
    return years_between_dates(birthdate, now).round(0) unless birthdate.nil?
    return nil unless efforts.count > 0
    approximate_age_array = []
    efforts.each do |effort|
      approximate_age_array << (years_between_dates(effort.event.first_start_time.to_date, now) + effort.age) unless effort.age.nil?
    end
    (approximate_age_array.inject(0.0) { |sum, el| sum + el } / approximate_age_array.size).round(0)
  end

  def years_between_dates(date1, date2)
    (date2 - date1) / 365.25
  end

  def unclaimed?
    claimant.nil?
  end

  def claimed?
    !unclaimed?
  end

  def self.where_email_matches(email)
    email.blank? ? nil : where(email: email.downcase)
  end

  def self.where_last_name_matches(last_name)
    where("lower(last_name) = ?", last_name.downcase) # TODO change to ILIKE for PGSQL production environment
  end

  def self.where_first_name_matches(first_name)
    where("lower(first_name) = ?", first_name.downcase) #TODO implement fuzzy matching and change to ILIKE for production
  end

  def self.where_name_matches(first_name, last_name)
    where_last_name_matches(last_name).where_first_name_matches(first_name)
  end

  # def self.where_age_approximates(age)
  #   map { |participant| participant.approximate_age == age ? participant : nil }.compact
  # end

end
