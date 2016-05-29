class Effort < ActiveRecord::Base
  include Auditable
  include PersonalInfo
  include Searchable
  include Matchable
  strip_attributes collapse_spaces: true
  enum gender: [:male, :female]
  enum data_status: [:bad, :questionable, :good] # nil = unknown, 0 = bad, 1 = questionable, 2 = good
  belongs_to :event, touch: true
  belongs_to :participant
  has_many :split_times, dependent: :destroy
  accepts_nested_attributes_for :split_times, :reject_if => lambda { |s| s[:time_from_start].blank? && s[:elapsed_time].blank? }

  attr_accessor :overdue_amount, :suggested_match

  validates_presence_of :event_id, :first_name, :last_name, :gender
  validates_uniqueness_of :participant_id, scope: :event_id, unless: 'participant_id.nil?'
  validates_uniqueness_of :bib_number, scope: :event_id, allow_nil: true

  before_save :reset_age_from_birthdate

  scope :sorted_by_finish_time, -> { select('efforts.*, splits.kind, split_times.time_from_start as time')
                                         .joins(:split_times => :split).where(splits: {kind: 1})
                                         .order('split_times.time_from_start') }
  scope :on_course, -> (course) { includes(:event).where(events: {course_id: course.id}) }
  scope :ordered_by_date, -> { includes(:event).order('events.start_time DESC') }

  def self.attributes_for_import
    id = ['id']
    foreign_keys = Effort.column_names.find_all { |x| x.include?('_id') }
    stamps = Effort.column_names.find_all { |x| x.include?('_at') | x.include?('_by') }
    (column_names - (id + foreign_keys + stamps)).map &:to_sym
  end

  def reset_time_from_start
    # If the starting split_time contains nonzero data, assume it means
    # this effort began that amount of time earlier or later than the event's normal start time
    return nil unless start_split_time
    if start_split_time.time_from_start != 0
      update(start_offset: start_split_time.time_from_start)
      start_split_time.update(time_from_start: 0)
    end
  end

  def reset_age_from_birthdate
    self.assign_attributes(age: TimeDifference.between(birthdate, event_start_time).in_years.to_i) if birthdate.present?
  end

  def self.reset_effort_ages
    counter = 0
    all.each do |effort|
      effort.reset_age_from_birthdate
      if effort.save
        counter += 1
      end
    end
    counter
  end

  def self.search(param)
    return all if param.blank?
    flexible_search(param)
  end

  def start_time
    event_start_time + start_offset
  end

  def start_time=(datetime)
    return unless datetime.present?
    event_time = event_start_time
    difference = TimeDifference.between(datetime, event_time).in_seconds
    # TimeDifference returns only positive values so make negative if appropriate
    self.start_offset = (datetime > event_time) ? difference : (difference * -1)
  end

  # Methods regarding split_times

  def finished?
    finish_split_time.present?
  end

  def in_progress?
    dropped_split_id.nil? && finish_split_time.nil?
  end

  def dropped?
    dropped_split_id.present?
  end

  def finish_status
    return "DNF" if dropped?
    split_time = finish_split_time
    return split_time.formatted_time_hhmmss if split_time
    "In progress"
  end

  # Methods for checking status during live event

  def due_next_where
    return nil if dropped?
    last_split = last_reported_split
    return nil if last_split.finish?
    event.next_split(last_split)
  end

  def overdue_by(cache = nil)
    Time.now - due_next_when(cache)
  end

  def due_next_when(cache = nil)
    event_start_time + start_offset + due_next_time_from_start(cache)
  end

  def expected_time_from_start(split, cache = nil)
    return nil if dropped?
    last_time = last_reported_split_time
    last_split = last_time.split
    return nil if last_split.finish?
    cache ||= SegmentCalculationsCache.new(event)
    current_segment = Segment.new(last_split, event.next_split(last_split))
    completed_segment = Segment.new(event.start_split, last_split)
    current_segment_calcs = cache.fetch_calculations(current_segment)
    completed_segment_calcs = cache.fetch_calculations(completed_segment)
    pace_factor = last_time.time_from_start / (completed_segment_calcs.mean || completed_segment.typical_time_by_terrain)
    last_time.time_from_start + (current_segment_calcs.mean * pace_factor)
  end

  def last_reported_split
    ordered_split_times.last.split
  end

  def last_reported_split_time
    ordered_split_times.last
  end

  def event_start_time
    event.start_time
  end

  def finish_split_time
    split_times.finish.first
  end

  def start_split_time
    split_times.start.first
  end

  def base_split_times
    split_times.base.ordered
  end

  def time_in_aid(split)
    time_array = split_times.where(split: split).order(:sub_split_id).pluck(:time_from_start)
    time_array.count > 1 ? time_array.last - time_array.first : nil
  end

  def total_time_in_aid # TODO reduce number of database calls
    total = 0
    split_times_out = split_times.out
    split_times_out.each do |unicorn|
      tia = time_in_aid(unicorn.split)
      total = tia ? total + tia : total
    end
    total
  end

  def likely_intended_time(military_time, split)
    units = %w(hours minutes seconds)
    seconds_into_day = military_time.split(':')
                           .map.with_index { |x, i| x.to_i.send(units[i]) }
                           .reduce(:+).to_i
    working_datetime = event_start_time.beginning_of_day + seconds_into_day
    working_datetime + ((((working_datetime - due_next_when) * -1) / 1.day).round(0) * 1.day)
  end

  def ordered_splits
    event.splits.ordered
  end

  def ordered_split_times
    split_times.ordered
  end

  def previous_split_time(split_time)
    ordered_times = ordered_split_times
    position = ordered_times.index(split_time)
    return nil if position.nil?
    position == 0 ? nil : ordered_times[position - 1]
  end

  def previous_valid_split_time(split_time)
    ordered_times = split_times.valid_status.union(id: split_time.id).ordered
    position = ordered_times.index(split_time)
    return nil if position.nil?
    position == 0 ? nil : ordered_times[position - 1]
  end

  def combined_places
    event.combined_places(self)
  end

  def overall_place
    event.overall_place(self)
  end

  def gender_place
    event.gender_place(self)
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
    age ? (TimeDifference.between(event_start_time.to_date, now).in_years + age).to_i : nil
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

  def self.sorted_including_dnf
    Effort.connection.execute("select t.effort_id, t.gender, t.split_id, t.time_from_start from
(select distinct on(ef.id)
ef.id as effort_id, ef.gender, s.id as split_id, s.distance_from_start, st.time_from_start
from efforts ef
left join split_times st on st.effort_id = ef.id
left join splits s on s.id = st.split_id
where ef.event_id = 4
order by ef.id, s.distance_from_start desc) as t
order by t.distance_from_start desc, t.time_from_start")
  end

  def self.distinct_join_table
    select('DISTINCT ON(efforts.id) efforts.id as effort_id, efforts.gender, splits.id as split_id, splits.distance_from_start, split_times.time_from_start')
        .joins(:split_times => :split)
        .order('efforts.id, splits.distance_from_start DESC')
  end


  def self.sorted(time_array = nil)
    return [] if self.count < 1
    return sorted_by_finish_time if first.event.simple?
    ids = self.pluck(:id)
    time_array ||= sorted_ultra_time_array
    time_array.keep_if { |row| ids.include?(row[0]) }
    efforts_from_ids(time_array.map { |x| x[0] })
  end

  def self.sorted_ultra_time_array(split_time_hash = nil)
    # Column 0 contains effort_ids, columns 1..-1 are time data
    return [] if self.count == 0
    event = first.event
    split_time_hash ||= event.split_time_hash
    result = self.pluck(:id).map { |effort_id| [effort_id] }
    event.ordered_split_ids.each do |split_id|
      hash = split_time_hash[split_id] ?
          Hash[split_time_hash[split_id].map { |row| [row[:effort_id], row[:time_from_start]] }] :
          {}
      result.collect! { |row| row << hash[row[0]] }
    end
    result.sort_by { |a| a[1..-1].reverse.map { |e| e || Float::INFINITY } }
  end

  def self.sorted_by_segment_time(segment)
    efforts_from_ids(ids_sorted_by_segment_time(segment))
  end

  def self.within_time_range(low_time, high_time)
    where(id: ids_within_time_range(low_time, high_time))
  end

  def self.efforts_from_ids(effort_ids)
    efforts_by_id = Effort.find(effort_ids).index_by(&:id)
    effort_ids.collect { |id| efforts_by_id[id] }
  end

  def set_dropped_split_id
    dropped_split_id =
        finish_split_time ?
            nil :
            split_times.joins(:split).joins(:effort)
                .order('efforts.id, splits.distance_from_start DESC')
                .first.split_id
    update(dropped_split_id: dropped_split_id)
    dropped_split_id
  end

  private

  def self.ids_within_time_range(low_time, high_time)
    effort_ids = self.pluck(:id)
    SplitTime.includes(:split).where(effort_id: effort_ids, splits: {kind: 1})
        .where(time_from_start: low_time..high_time).pluck(:effort_id)
  end

  def self.ids_sorted_by_segment_time(segment)
    effort_ids = self.pluck(:id)
    segment.times.keep_if { |k, _| effort_ids.include?(k) }.sort_by { |_, v| v }.map { |x| x[0] }
  end

end