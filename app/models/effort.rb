class Effort < ActiveRecord::Base
  include PersonalInfo
  enum gender: [:male, :female]
  belongs_to :event
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

  def finished?
    return false if split_times.count < 1
    split_times.reverse.each do |split_time|
      return true if split_time.split.kind == "finish"
    end
    false
  end

  def finish_status
    return "DNF" if dropped?
    return finish_split_time.formatted_time if finished?
    "In progress"
  end

  def finish_split_time
    return nil if split_times.count < 1
    split_times.reverse.each do |split_time|
      return split_time if split_time.split.kind == 'finish'
    end
    nil
  end

  def start_split_time
    return nil if split_times.count < 1
    split_times.each do |split_time|
      return split_time if split_time.split.kind == 'start'
    end
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

  def exact_matching_participant # Suitable for automated matcher
    participants = Participant.last_name_matches(last_name, rigor: 'exact')
                       .first_name_matches(first_name, rigor: 'exact').gender_matches(gender)
    exact_match = Participant.age_matches(age_today, participants, 'soft')
    exact_match.count == 1 ? exact_match.first : nil # Convert single match to object; don't pass if more than one match
  end

  def closest_matching_participant # Requires human review
    participant_with_same_name ||
        participant_with_nickname ||
        participant_changed_last_name ||
        participant_changed_first_name ||
        participant_same_full_name
    # return participant_with_nickname if participant_with_nickname
  end

  def participant_with_same_name
    Participant.last_name_matches(last_name).first_name_matches(first_name).first
  end

  def participant_with_nickname # Need to find a good nickname gem
    # Participant.last_name_matches(last_name).first_name_nickname(first_name).first
  end

  def participant_changed_last_name # To find women who may have changed their last names
    participants = Participant.female.first_name_matches(first_name).state_matches(state_code).all
    Participant.age_matches(age_today, participants).first
  end

  def participant_changed_first_name # To pick up discrepancies in first names #TODO use levensthein alagorithm
    participants = Participant.last_name_matches(last_name).gender_matches(gender).all
    Participant.age_matches(age_today, participants).first
  end

  def participant_same_full_name # For situations where middle names are sometimes included with first_name and sometimes with last_name
    participants = Participant.gender_matches(gender) # To limit pool of search options
    Participant.full_name_matches(full_name, participants).first
  end

  def approximate_age_today
    now = Time.now.utc.to_date
    age ? (years_between_dates(event.first_start_time.to_date, now) + age).to_i : nil
  end

  def base_split_times
    return_array = []
    split_times.each do |split_time|
      if split_time.split.sub_order == 0
        return_array << split_time
      end
    end
    return_array.sort_by { |x| x.split.distance_from_start }
  end

end
