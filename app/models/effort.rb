class Effort < ActiveRecord::Base
  include Auditable
  include Matchable
  include PersonalInfo
  include Searchable
  include StatisticalMethods
  enum gender: [:male, :female]
  enum data_status: [:bad, :questionable, :good] # nil = unknown, 0 = bad, 1 = questionable, 2 = good
  belongs_to :event, touch: true
  belongs_to :participant
  has_many :split_times, dependent: :destroy
  accepts_nested_attributes_for :split_times, :reject_if => lambda { |s| s[:time_from_start].blank? && s[:time_as_entered].blank? }


  validates_presence_of :event_id, :first_name, :last_name, :gender, :start_time
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
      update(start_time: start_time + start_split_time.time_from_start)
      start_split_time.update(time_from_start: 0)
    end
  end

  # Methods regarding split_times

  def finished?
    split_time = split_times.joins(:split).where(splits: {kind: 1}).first
    split_time.present?
  end

  def finish_status
    return "DNF" if dropped?
    return finish_split_time.formatted_time_hhmmss if finished?
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

  def time_in_aid(split)
    group = event.waypoint_group(split)
    segment_time(group.first, group.last)
  end

  def total_time_in_aid
    total = 0
    base_split_times.each do |unicorn|
      total = total + unicorn.time_in_aid
    end
    total
  end

  def ordered_splits
    event.splits.ordered
  end

  def ordered_split_times
    split_times.includes(:split).order('splits.distance_from_start', 'splits.sub_order')
  end

  def ordered_valid_split_times
    valid_split_times.order('splits.distance_from_start', 'splits.sub_order')
  end

  def valid_split_times
    valid = [nil, 2]
    split_times.includes(:split).where(data_status: valid)
  end

  def previous_split_time(split_time)
    ordered_times = ordered_split_times
    position = ordered_times.index(split_time)
    return nil if position.nil?
    position == 0 ? nil : ordered_times[position - 1]
  end

  def previous_valid_split_time(split_time)
    ordered_times = ordered_valid_split_times
    position = ordered_times.index(split_time)
    return nil if position.nil?
    position == 0 ? nil : ordered_times[position - 1]
  end

  def overall_place
    (event.efforts.ids_sorted_ultra_style.index(id)) + 1
  end

  def gender_place
    efforts = event.efforts.sorted_ultra_style
    ids = efforts.map(&:id)
    efforts.map(&:gender)[0..ids.index(id)].count(gender)
  end

  def segment_time(split1, split2 = nil)
    if split2.nil?
      return nil if split1.nil?
      return 0 if split1.start?
      end_split_time = split_times.where(split_id: split1.id).first
      return nil unless end_split_time
      start_split_time = end_split_time.previous_split_time
      return nil unless start_split_time
      (end_split_time.time_from_start - start_split_time.time_from_start)
    else
      end_split_time = split_times.where(split_id: split2.id).first
      start_split_time = split_times.where(split_id: split1.id).first
      end_split_time && start_split_time ? (end_split_time.time_from_start - start_split_time.time_from_start) : nil
    end
  end

  def segment_velocity(split1, split2 = nil)
    return nil if split1.nil?
    if split2.nil?
      return 0 if split1.start?
      event.segment_distance(split1) / segment_time(split1)
    else
      return 0 if split1.distance_from_start == split2.distance_from_start
      event.segment_distance(split1, split2) / segment_time(split1, split2)
    end
  end

  def self.gender_group(split1, split2, gender) # TODO Intersect queries to select only those efforts that include both splits
    # scope :includes_split1, -> { includes(:event => :splits).where(splits: {id: split1.id}) }
    # scope :includes_split2, -> { includes(:event => :splits).where(splits: {id: split2.id}) }
    # scope :includes_both_splits, -> { intersect_scope(includes_split1, includes_split2) }
    case gender
      when 'male'
        includes(:event => :splits).male.where(splits: {id: split2.id})
      when 'female'
        includes(:event => :splits).female.where(splits: {id: split2.id})
      else
        includes(:event => :splits).where(splits: {id: split2.id})
    end
  end

  # Age methods

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

  # Methods for reconciliation with participants

  def unreconciled?
    participant_id.nil?
  end

  def self.unreconciled
    where(participant_id: nil)
  end

  # Sorting class methods

  def self.sorted_by_finish_time # Excludes DNFs from result
    efforts_from_ids(ids_sorted_by_finish_time)
  end

  def self.sorted_ultra_style # Sorts DNFs by distance covered before drop, with farther efforts getting higher placement
    efforts_from_ids(ids_sorted_ultra_style)
  end

  def self.sorted_by_segment_time(first_split, second_split)
    efforts_from_ids(ids_sorted_by_segment_time(first_split, second_split))
  end

  def self.within_time_range(low_time, high_time)
    where(id: ids_within_time_range(low_time, high_time))
  end

  # Admin functions to set data status

  def set_time_data_status_best # Sets data status for all split_times belonging to the instance effort
    ordered_split_times.each do |split_time|
      split_time.update(data_status: get_actual_status(split_time)) unless split_time.confirmed?
    end
    set_self_data_status
  end

  def get_actual_status(split_time)
    tfs_solo = split_time.tfs_solo_data_status
    return tfs_solo if tfs_solo == 0
    tfs_data_set = split_time.split.split_times.pluck(:time_from_start)
    tfs_statistical = split_time.split.start? | (tfs_data_set.count < 10) ? nil :
        split_time.tfs_statistical_data_status(Effort.low_and_high_params(tfs_data_set))
    return tfs_statistical if tfs_statistical == 0
    split_time.update(data_status: nil) if split_time.not_valid? # Allows split_time to be located among ordered valid splits
    previous = previous_valid_split_time(split_time)
    st_solo = split_time.st_solo_data_status(previous)
    return st_solo if st_solo == 0
    st_data_set = previous ? event.course.segment_time_data_set(previous.split, split_time.split).values : []
    st_statistical = (split_time.split.start? == false &&
        (st_data_set.count >= 10) &&
        split_time.not_in_waypoint_group_with(previous)) ?
        split_time.st_statistical_data_status(Effort.low_and_high_params(st_data_set), previous) : nil
    [tfs_solo, tfs_statistical, st_solo, st_statistical].compact.min
  end

  def set_self_data_status
    time_status_data = split_times.pluck(:data_status)
    status = case
               when time_status_data.exclude?(nil) && (time_status_data.min >= 2) # All times are good
                 'good'
               when time_status_data.compact.min == 1 # At least one questionable time but no bad times
                 'questionable'
               when time_status_data.compact.min == 0 # At least one bad time
                 'bad'
               else # Not all known good but no questionable or bad
                 nil
             end
    self.update(data_status: status)
  end

  private

  def self.ids_within_time_range(low_time, high_time)
    effort_ids = all.map(&:id)
    SplitTime.includes(:split, :effort).where(efforts: {id: effort_ids}, splits: {kind: 1})
        .where(time_from_start: low_time..high_time).map(&:effort_id)
  end

  def self.ids_sorted_by_finish_time
    effort_ids = all.map(&:id)
    SplitTime.includes(:split, :effort).where(efforts: {id: effort_ids}, splits: {kind: 1})
        .order(:time_from_start).map(&:effort_id)
  end

  def self.ids_sorted_by_segment_time(first_split, second_split)
    effort_ids = all.map(&:id)
    first_split_times = SplitTime.includes(:split, :effort).where(efforts: {id: effort_ids}, splits: {id: first_split.id})
    first_hash = Hash[first_split_times.pluck(:effort_id, :time_from_start)]
    second_split_times = SplitTime.includes(:split, :effort).where(efforts: {id: effort_ids}, splits: {id: second_split.id})
    second_hash = Hash[second_split_times.pluck(:effort_id, :time_from_start)]
    sort_hash = {}
    second_hash.each do |effort_id, time|
      sort_hash[effort_id] = time - first_hash[effort_id] if first_hash[effort_id]
    end
    Hash[sort_hash.sort_by { |k, v| [v ? 0 : 1, v] }].keys
  end

  def self.ids_sorted_ultra_style
    return [] if all.count == 0
    raise "Efforts don't belong to same event" if all.group(:event_id).count.size != 1
    event = first.event
    sort_hash = all.index_by &:id
    splits = event.splits.includes(:split_times).ordered
    splits.each do |split|
      time_hash = split.split_times.where(effort_id: sort_hash.keys).index_by &:effort_id
      sort_hash.each_key do |key|
        time = time_hash[key] ? time_hash[key].time_from_start : nil
        sort_hash[key] = time
      end
      sort_hash = Hash[sort_hash.sort_by { |k, v| [v ? 0 : 1, v] }]
    end
    sort_hash.keys
  end

  def self.efforts_from_ids(effort_ids)
    efforts_by_id = Effort.find(effort_ids).index_by(&:id)
    effort_ids.collect { |id| efforts_by_id[id] }
  end


end
