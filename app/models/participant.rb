class Participant < ActiveRecord::Base  #TODO: create class Person with subclasses Participant and Effort
  enum gender: [:male, :female]
  has_many :interests, dependent: :destroy
  has_many :users, :through => :interests
  has_many :efforts

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
    (approximate_age_array.inject(0.0) { |sum,el| sum + el } / approximate_age_array.size).round(0)
  end

  def years_between_dates(date1, date2)
    (date2 - date1) / 365.25
  end
end
