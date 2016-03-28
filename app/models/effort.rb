class Effort < ActiveRecord::Base
  enum gender: [:male, :female]
  belongs_to :event
  belongs_to :participant
  has_many :split_times, dependent: :destroy

  validates_presence_of :event_id
  validates_uniqueness_of :participant_id, scope: :event_id, unless: 'participant_id.nil?'
  validates_uniqueness_of :bib_number, scope: :event_id, allow_nil: true

  def self.columns_for_import
    id = ["id"]
    foreign_keys = Effort.column_names.find_all { |x| x.include?("_id") }
    stamps = Effort.column_names.find_all { |x| x.include?("_at") | x.include?("_by") }
    (column_names - (id + foreign_keys + stamps)).map &:to_sym
  end

  def full_name
    first_name + " " + last_name
  end

  def bio
    age.nil? ? gender.titlecase : "#{gender.titlecase}, #{age}"
  end

  def finished?
    return false if split_times.count < 1
    split_times.each do |split_time|
      return true if split_time.split.kind == "finish"
    end
    false
  end

  def finish_time
    return nil if split_times.count < 1
    split_times.each do |split_time|
      return split_time.time_from_start if split_time.split.kind == "finish"
    end
    nil
  end

  def finish_time_formatted
    total_seconds = finish_time
    seconds = total_seconds % 60
    minutes = (total_seconds / 60) % 60
    hours = total_seconds / (60 * 60)

    format("%02d:%02d:%02d", hours, minutes, seconds)
  end

  def status
    return "DNF" if dropped?
    return finish_time_formatted if finished?
    "In progress"
  end

end
