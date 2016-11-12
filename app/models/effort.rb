class Effort < ActiveRecord::Base
  include Auditable
  include Concealable
  include PersonalInfo
  include Searchable
  include Matchable
  strip_attributes collapse_spaces: true
  enum gender: [:male, :female]
  enum data_status: [:bad, :questionable, :good] # nil = unknown, 0 = bad, 1 = questionable, 2 = good
  belongs_to :event
  belongs_to :participant
  has_many :split_times, dependent: :destroy
  accepts_nested_attributes_for :split_times, :reject_if => lambda { |s| s[:time_from_start].blank? && s[:elapsed_time].blank? }

  attr_accessor :start_time_attr, :over_under_due, :last_reported_split_time_attr, :next_expected_split_time,
                :suggested_match, :segment_time
  attr_writer :overall_place, :gender_place

  validates_presence_of :event_id, :first_name, :last_name, :gender
  validates_uniqueness_of :participant_id, scope: :event_id, unless: 'participant_id.nil?'
  validates_uniqueness_of :bib_number, scope: :event_id, allow_nil: true

  before_save :reset_age_from_birthdate

  scope :valid_status, -> { where(data_status: [nil, data_statuses[:good], data_statuses[:confirmed]]) }
  scope :sorted_by_finish_time, -> { select('efforts.*, splits.kind, split_times.time_from_start as time')
                                         .joins(:split_times => :split).where(splits: {kind: 1})
                                         .order('split_times.time_from_start') }
  scope :ordered_by_date, -> { includes(:event).order('events.start_time DESC') }
  scope :on_course, -> (course) { includes(:event).where(events: {course_id: course.id}) }
  scope :within_time_range, -> (low_time, high_time) { includes(:split_times => :split)
                                                           .where(splits: {kind: 1},
                                                                  split_times: {time_from_start: low_time..high_time}) }
  scope :unreconciled, -> { where(participant_id: nil) }

  delegate :race, to: :event

  def self.attributes_for_import
    id = ['id']
    foreign_keys = Effort.column_names.find_all { |x| x.include?('_id') }
    stamps = Effort.column_names.find_all { |x| x.include?('_at') | x.include?('_by') }
    (column_names - (id + foreign_keys + stamps)).map &:to_sym
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
    return where(bib_number: param.to_i) if param.to_i > 0
    flexible_search(param)
  end

  def start_time
    start_time_attr || start_time_calculated
  end

  def start_time_calculated
    event_start_time + start_offset
  end

  def start_time=(datetime)
    return unless datetime.present?
    new_datetime = datetime.is_a?(Hash) ? Time.zone.local(*datetime.values) : datetime
    event_time = event_start_time
    difference = TimeDifference.between(new_datetime, event_time).in_seconds
    # TimeDifference returns only positive values so make negative if appropriate
    self.start_offset = (new_datetime > event_time) ? difference : -difference
  end

  # Methods regarding split_times

  def last_reported_split_time
    last_reported_split_time_attr || last_reported_split_time_calc
  end

  def last_reported_split_time_calc
    ordered_split_times.last
  end

  def finished?
    finish_split_time.present?
  end

  def in_progress?
    dropped_split_id.nil? && finish_split_time.nil?
  end

  def dropped?
    dropped_split_id.present?
  end

  def started?
    split_times.present?
  end

  def finish_status
    return "DNF" if dropped?
    return "Not yet started" unless started?
    split_time = finish_split_time
    return split_time.formatted_time_hhmmss if split_time
    "In progress"
  end

  def event_start_time
    event.start_time
  end

  def event_name
    event.name
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
    time_array = split_times.where(split: split).order(:sub_split_bitkey).pluck(:time_from_start)
    time_array.count > 1 ? time_array.last - time_array.first : nil
  end

  def total_time_in_aid
    total = 0
    split_times_hash = ordered_split_times.group_by(&:split_id)
    split_times_hash.each_key do |unicorn|
      time_array = split_times_hash[unicorn].map(&:time_from_start)
      tia = time_array.last - time_array.first
      total = tia ? total + tia : total
    end
    total
  end

  def likely_intended_time(military_time, split, event_segment_calcs = nil)
    units = %w(hours minutes seconds)
    seconds_into_day = military_time.split(':')
                           .map.with_index { |x, i| x.to_i.send(units[i]) }
                           .reduce(:+).to_i
    return nil if seconds_into_day >= 1.day
    working_datetime = event_start_time.beginning_of_day + seconds_into_day
    expected = expected_day_and_time({split.id => SubSplit::IN_BITKEY}, event_segment_calcs)
    expected ? working_datetime + ((((working_datetime - expected) * -1) / 1.day).round(0) * 1.day) : nil
  end

  def expected_day_and_time(bitkey_hash, event_segment_calcs = nil)
    expected_tfs = expected_time_from_start(bitkey_hash, event_segment_calcs)
    expected_tfs ? start_time + expected_tfs : nil
  end

  def expected_time_from_start(bitkey_hash, event_segment_calcs = nil)
    split_times_hash = split_times.index_by(&:bitkey_hash)
    ordered_splits = event.ordered_splits.to_a
    ordered_bitkey_hashes = ordered_splits.map(&:sub_split_bitkey_hashes).flatten
    start_bitkey_hash = ordered_bitkey_hashes.first
    return nil unless split_times_hash[start_bitkey_hash].present?
    return 0 if bitkey_hash == start_bitkey_hash
    relevant_bitkey_hashes = ordered_bitkey_hashes[0..(ordered_bitkey_hashes.index(bitkey_hash) - 1)]
    prior_split_time = relevant_bitkey_hashes.collect { |bh| split_times_hash[bh] }.compact.last
    prior_bitkey_hash = prior_split_time.bitkey_hash
    event_segment_calcs ||= EventSegmentCalcs.new(event)
    completed_segment = Segment.new(start_bitkey_hash,
                                    prior_bitkey_hash,
                                    ordered_splits.find { |split| split.id == start_bitkey_hash.keys.first },
                                    ordered_splits.find { |split| split.id == prior_bitkey_hash.keys.first })
    subject_segment = Segment.new(prior_bitkey_hash,
                                  bitkey_hash,
                                  ordered_splits.find { |split| split.id == prior_bitkey_hash.keys.first },
                                  ordered_splits.find { |split| split.id == bitkey_hash.keys.first })
    completed_segment_calcs = event_segment_calcs.fetch_calculations(completed_segment)
    subject_segment_calcs = event_segment_calcs.fetch_calculations(subject_segment)
    pace_baseline = completed_segment_calcs.mean ?
        completed_segment_calcs.mean :
        completed_segment.typical_time_by_terrain
    pace_factor = pace_baseline == 0 ? 1 :
        prior_split_time.time_from_start / pace_baseline
    subject_segment_calcs.mean ?
        (prior_split_time.time_from_start + (subject_segment_calcs.mean * pace_factor)) :
        (prior_split_time.time_from_start + (subject_segment.typical_time_by_terrain * pace_factor))
  end


  def ordered_splits
    event.splits.ordered
  end

  def ordered_split_times
    split_times.ordered
  end

  def combined_places
    @combined_places ||= event.combined_places(self)
  end

  def overall_place
    @overall_place ||= event.overall_place(self)
  end

  def gender_place
    @gender_place ||= event.gender_place(self)
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

  def unreconciled?
    participant_id.nil?
  end

  def self.sorted_with_finish_status
    raw_sort = select('DISTINCT ON(efforts.id) efforts.*, splits.id as final_split_id, splits.base_name as final_split_name, splits.distance_from_start, split_times.time_from_start, split_times.sub_split_bitkey')
                   .joins(:split_times => :split)
                   .order('efforts.id, splits.distance_from_start DESC, split_times.sub_split_bitkey DESC')
    sorted_efforts = raw_sort.sort_by { |row| [row.dropped_split_id ? 1 : 0, -row.distance_from_start, row.time_from_start, row.gender, row.age ? -row.age : 0] }
    sorted_efforts.each_with_index do |effort, i|
      effort.overall_place = i + 1
      effort.gender_place = sorted_efforts[0..i].count { |e| e.gender == effort.gender }
    end
    sorted_efforts
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

end