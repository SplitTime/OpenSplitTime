class Effort < ActiveRecord::Base
  include Matchable
  include PersonalInfo
  include Searchable
  enum gender: [:male, :female]
  enum data_status: [:bad, :questionable, :good] # nil = unknown, 0 = bad, 1 = questionable, 2 = good
  belongs_to :event, touch: true
  belongs_to :participant
  has_many :split_times, dependent: :destroy

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
    split_times.includes(:split).order('splits.distance_from_start', 'splits.sub_order')
  end

  def place
    (event.efforts.ids_sorted_ultra_style.index(id)) + 1
  end

  def gender_place
    efforts = event.efforts.sorted_ultra_style
    ids = efforts.map(&:id)
    efforts.map(&:gender)[0..ids.index(id)].count(gender)
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

  def unreconciled?
    participant_id.nil?
  end

  def self.unreconciled
    where(participant_id: nil)
  end

  def self.sorted_by_finish_time # Excludes DNFs from result
    efforts_from_ids(ids_sorted_by_finish_time)
  end

  def self.sorted_ultra_style # Sorts DNFs by distance covered before drop, with farther efforts getting higher placement
    efforts_from_ids(ids_sorted_ultra_style)
  end

  private

  def self.ids_sorted_by_finish_time
    effort_ids = all.map(&:id)
    SplitTime.includes(:split, :effort).where(efforts: {id: effort_ids}, splits: {kind: 1}).order(:time_from_start).map(&:effort_id)
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
