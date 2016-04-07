class Effort < ActiveRecord::Base
  include Matchable
  include PersonalInfo
  include Searchable
  enum gender: [:male, :female]
  belongs_to :event, touch: true
  belongs_to :participant
  has_many :split_times, dependent: :destroy

  validates_presence_of :event_id, :first_name, :last_name, :gender
  validates_uniqueness_of :participant_id, scope: :event_id, unless: 'participant_id.nil?'
  validates_uniqueness_of :bib_number, scope: :event_id, allow_nil: true

  def self.columns_for_import
    id = ["id"]
    foreign_keys = Effort.column_names.find_all { |x| x.include?("_id") }
    stamps = Effort.column_names.find_all { |x| x.include?("_at") | x.include?("_by") }
    (column_names - (id + foreign_keys + stamps)).map &:to_sym
  end

  def reset_time_from_start

    # If the starting split_time contains nonzero data, assume it means
    # this effort began that amount of time later than the event's normal start time

    return nil unless start_split_time
    if start_split_time.time_from_start != 0
      update_attributes(start_time: start_time + start_split_time.time_from_start)
      start_split_time.update_attributes(time_from_start: 0)
    end

  end

  # Methods regarding split_times

  def finished?
    split_time = split_times.joins(:split).where(splits: {kind: 1}).first
    split_time.present?
  end

  def finish_status
    return "DNF" if dropped?
    return finish_split_time.formatted_time if finished?
    "In progress"
  end

  def finish_split_time
    split_times.joins(:split).where(splits: {kind: 1}).first
  end

  def start_split_time
    split_times.joins(:split).where(splits: {kind: 0}).first
  end

  def base_split_times
    split_times.joins(:split).where(splits: {sub_order: 0}).order('splits.distance_from_start')
  end

  def ordered_splits
    event.splits.ordered
  end

  def ordered_split_times
    split_times = []
    ordered_splits.each do |split|
      split_times << SplitTime.where(split_id: split.id, effort_id: id).first
    end
    split_times
  end

  def place
    event.race_sorted_ids.index(id) + 1
  end

  def gender_place
    place_array = event.race_sorted_ids
    my_index = place_array.index(id)
    return 1 if my_index == 0
    my_gender_place = 1
    place_array[0, my_index - 1].each do |effort_id|
      my_gender_place += 1 if Effort.find(effort_id).gender == gender
    end
    my_gender_place
  end

  def approximate_age_today
    now = Time.now.utc.to_date
    age ? (years_between_dates(event.first_start_time.to_date, now) + age).to_i : nil
  end

  def self.age_matches(param, efforts, rigor = 'soft')
    return none unless param
    matches = []
    threshold = rigor == 'exact' ? 1 : 2
    efforts.each do |effort|
      age = effort.age_today
      return none unless age
      if (age - param).abs < threshold
        matches << effort
      end
    end
    matches
  end

end
