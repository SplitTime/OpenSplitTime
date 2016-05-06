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
    segment_time(Segment.new(group.first, group.last))
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
    split_times.valid_status.includes(:split).order('splits.distance_from_start', 'splits.sub_order')
  end

  def previous_split_time(split_time)
    ordered_times = ordered_split_times
    position = ordered_split_times.index(split_time)
    return nil if position.nil?
    position == 0 ? nil : ordered_times[position - 1]
  end

  def previous_valid_split_time(split_time)
    ordered_times = split_times.valid_status.union(id: split_time.id).includes(:split).order('splits.distance_from_start', 'splits.sub_order')
    position = ordered_times.index(split_time)
    return nil if position.nil?
    position == 0 ? nil : ordered_times[position - 1]
  end

  def combined_places
    efforts = event.efforts.sorted_ultra_style
    ids = efforts.map(&:id)
    gender_place = efforts.map(&:gender)[0..ids.index(id)].count(gender)
    overall_place = ids.index(id) + 1
    return overall_place, gender_place
  end

  def overall_place
    (event.efforts.ids_sorted_ultra_style.index(id)) + 1
  end

  def gender_place
    efforts = event.efforts.sorted_ultra_style
    ids = efforts.map(&:id)
    efforts.map(&:gender)[0..ids.index(id)].count(gender)
  end

  def segment_time(segment)
    return 0 if segment.end_split.start?
    times = split_times.where(split_id: segment.split_ids).index_by(&:split_id)
    end_split_time = times[segment.end_id]
    begin_split_time = times[segment.begin_id]
    end_split_time && begin_split_time ? (end_split_time.time_from_start - begin_split_time.time_from_start) : nil
  end

  def segment_velocity(segment)
    segment.distance / segment_time(segment)
  end

  def self.gender_group(segment, gender) # TODO Intersect queries to select only those efforts that include both splits
    # scope :includes_split1, -> { includes(:event => :splits).where(splits: {id: split1.id}) }
    # scope :includes_split2, -> { includes(:event => :splits).where(splits: {id: split2.id}) }
    # scope :includes_both_splits, -> { intersect_scope(includes_split1, includes_split2) }
    case gender
      when 'male'
        includes(:event => :splits).male.where(splits: {id: segment.end_id})
      when 'female'
        includes(:event => :splits).female.where(splits: {id: segment.end_id})
      else
        includes(:event => :splits).where(splits: {id: segment.end_id})
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

  def self.sorted_by_segment_time(segment)
    efforts_from_ids(ids_sorted_by_segment_time(segment))
  end

  def self.within_time_range(low_time, high_time)
    where(id: ids_within_time_range(low_time, high_time))
  end

  # Admin functions to set data status

  def set_data_status
    Effort.where(id: id).set_data_status
  end

  def self.set_data_status
    update_effort_hash = {}
    event = Event.find(all.first.event_id)
    split_ids = event.ordered_splits.pluck(:id)
    cache = SegmentCalculationsCache.new(event)
    split_times = SplitTime.includes(:effort).where(effort_id: all.pluck(:id))

    all.each do |effort|
      status_array = []
      update_split_time_hash = {}
      effort_split_times = split_times.where(effort_id: effort.id).index_by(&:split_id)
      ordered_split_times = split_ids.collect { |id| effort_split_times[id] }
      start_split_time = ordered_split_times.first
      latest_valid_split_time = start_split_time

      ordered_split_times.each do |split_time|
        next if split_time.nil?
        if split_time.confirmed?
          latest_valid_split_time = split_time
          next
        end
        segment = Segment.new(latest_valid_split_time.split, split_time.split)
        segment_time = segment.end_split.start? ?
            split_time.time_from_start :
            split_time.time_from_start - latest_valid_split_time.time_from_start
        status = cache.get_data_status(segment, segment_time)
        status_array << status
        latest_valid_split_time = split_time if status == :good
        update_split_time_hash[split_time.id] = status if status != split_time.data_status.try(:to_sym)
      end

      BulkUpdateService.bulk_update_split_time_status(update_split_time_hash)
      effort_status = DataStatus.get_lowest_data_status(status_array)
      update_effort_hash[effort.id] = effort_status if effort_status != effort.data_status.try(:to_sym)
    end

    BulkUpdateService.bulk_update_effort_status(update_effort_hash)
  end

  def self.efforts_from_ids(effort_ids)
    efforts_by_id = Effort.find(effort_ids).index_by(&:id)
    effort_ids.collect { |id| efforts_by_id[id] }
  end

  private

  def self.ids_within_time_range(low_time, high_time)
    effort_ids = self.pluck(:id)
    SplitTime.includes(:split).where(effort_id: effort_ids, splits: {kind: 1})
        .where(time_from_start: low_time..high_time).pluck(:effort_id)
  end

  def self.ids_sorted_by_finish_time
    effort_ids = self.pluck(:id)
    SplitTime.includes(:split, :effort).where(efforts: {id: effort_ids}, splits: {kind: 1})
        .order(:time_from_start).pluck(:effort_id)
  end

  def self.ids_sorted_by_segment_time(segment)
    effort_ids = self.pluck(:id)
    segment.times.keep_if { |k, _| effort_ids.include?(k) }.sort_by { |_, v| v }.map { |x| x[0] }
  end

  def self.ids_sorted_ultra_style
    sorted_ultra_time_array.map { |x| x[0] }
  end

  def self.sorted_ultra_time_array(with_start = false)
    # Do sort in memory using an ultra_time_array
    return [] if all.count == 0
    raise "Efforts don't belong to same event" if all.group(:event_id).count.size != 1
    # First column (effort id keys) is ignored for the sort
    # Last column (array of data_statuses) is ignored for the sort
    all.create_ultra_time_array(with_start).sort_by { |a| a[1..-2].reverse.map { |e| e || Float::INFINITY } }
  end

  def self.create_ultra_time_array(with_start = false)
    # Column 0 contains effort_ids, columns 1..-2 are time data, column -1 is an array of data statuses
    event = Event.includes(:efforts).where(id: all.first.event_id).first
    event_efforts = event.efforts.pluck(:id)
    tfs_result = event_efforts.map { |x| [x] }
    ds_result = event_efforts.map { |x| [x, nil] } # The nil is a placeholder for the row's collective data status
    time_hashes, status_hashes = event.time_hashes(true)
    event.ordered_splits.each do |split|
      next if split.start? unless with_start
      tfs_hash = time_hashes[split.id]
      tfs_result.collect! { |e| e << tfs_hash[e[0]] }
      ds_hash = status_hashes[split.id]
      ds_result.collect! { |e| e << ds_hash[e[0]] }
    end
    ds_result.each { |x| x[1] = x[2..-1].compact.min }
    ds_big_hash = Hash[ds_result.map { |r| [r[0], r[1..-1]] }]
    tfs_result.collect! { |e| e << ds_big_hash[e[0]] }
  end

end
