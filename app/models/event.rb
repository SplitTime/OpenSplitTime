class Event < ActiveRecord::Base
  include Auditable
  include SplitMethods
  belongs_to :course, touch: true
  belongs_to :race
  has_many :efforts, dependent: :destroy
  has_many :event_splits, dependent: :destroy
  has_many :splits, through: :event_splits

  validates_presence_of :course_id, :name, :first_start_time
  validates_uniqueness_of :name, case_sensitive: false

  def all_splits_on_course?
    splits.each do |split|
      return false if split.course_id != course_id
    end
    true
  end

  def reconcile_exact_matches
    unreconciled_efforts.each do |effort|
      @exact_match = effort.exact_matching_participant
      if @exact_match
        @exact_match.pull_data_from_effort(effort)
      elsif effort.suggest_close_match

      end
    end
  end

  def find_unmatched_efforts
    unreconciled_efforts.each do |effort|

    end
  end

  def assign_participants_to_efforts(ids)
    id_hash = Hash[*ids.to_a.flatten.map(&:to_i)]
    efforts = Effort.find(id_hash.keys).index_by(&:id)
    participants = Participant.find(id_hash.values).index_by(&:id)
    id_hash.each do |effort_id, participant_id|
      participants[participant_id].pull_data_from_effort(efforts[effort_id])
    end
  end

  def reconciled_efforts
    efforts.where.not(participant_id: nil)
  end

  def unreconciled_efforts
    efforts.where(participant_id: nil)
  end

  def unreconciled_efforts?
    unreconciled_efforts.count > 0
  end

  def set_all_course_splits
    splits << course.splits
  end

  def set_data_status(efforts_param = nil)
    efforts = efforts_param || self.efforts
    efforts.set_data_status
  end

  def time_hashes_all_similar_events
    result_hash = {}
    event_split_ids = ordered_split_ids
    complete_hash = SplitTime.where(split_id: event_split_ids).pluck_to_hash(:split_id, :effort_id, :time_from_start).group_by { |row| row[:split_id] }
    event_split_ids.each do |split_id|
      result_hash[split_id] = Hash[complete_hash[split_id].map { |row| [row[:effort_id], row[:time_from_start]] }]
    end
    result_hash
  end

  def split_time_hash
    SplitTime.where(effort: efforts)
        .pluck_to_hash(:split_id, :effort_id, :time_from_start, :data_status)
        .group_by { |row| row[:split_id] }
  end

  def sorted_ultra_time_array(split_time_hash = nil)
    efforts.sorted_ultra_time_array(split_time_hash)
  end

  def data_status_hash(split_time_hash = nil)
    # Keys are effort_ids; Value is an array with column 0 effort status, columns 1..-1 time status
    return [] if efforts.count == 0
    split_time_hash ||= self.split_time_hash
    event_effort_ids = efforts.pluck(:id)
    result = event_effort_ids.map { |x| [x, nil] } # The nil is a placeholder for the row's collective data status
    ordered_split_ids.each do |split_id|
      hash = Hash[split_time_hash[split_id].map { |row| [row[:effort_id], row[:data_status]]}]
      result.collect! { |row| row << hash[row[0]] }
    end
    result = result.each { |row| row[1] = row[2..-1].compact.min } # Set row[1] to the minimum data status of the other rows
    Hash[result.map { |row| [row[0], row[1..-1]] }]
  end

  def efforts_sorted
    simple? ?
        efforts.sorted_by_finish_time :
        Effort.efforts_from_ids(sorted_ultra_time_array.map { |x| x[0] })
  end

  def ids_sorted
    simple? ?
        efforts.sorted_by_finish_time.pluck(:id) :
        sorted_ultra_time_array.map { |x| x[0] }
  end

  def combined_places(effort)
    ids = ids_sorted
    overall_place = ids.index(effort.id) + 1
    genders = Hash[efforts.pluck(:id, :gender)]
    genders_sorted = ids.map { |id| genders[id] }
    gender_place = genders_sorted[0...overall_place].count(Effort.genders[effort.gender])
    return overall_place, gender_place
  end

  def overall_place(effort)
    ids_sorted.index(effort.id) + 1
  end

  def gender_place(effort)
    combined_places(effort)[1]
  end

  # Methods for monitoring efforts while event is live

  def efforts_dropped
    efforts.where.not(dropped_split_id: nil).pluck(:id)
  end

  def efforts_finished
    efforts.sorted_by_finish_time.pluck(:id)
  end

  def efforts_in_progress
    unfinished_effort_ids = efforts.pluck(:id) - efforts_finished
    efforts.where(id: unfinished_effort_ids, dropped_split_id: nil)
  end

  def efforts_overdue # Returns an array of efforts with overdue_amount attribute
    result = []
    current_tfs = Time.now - first_start_time
    cache = SegmentCalculationsCache.new(self)
    efforts_in_progress.each do |effort|
      effort.overdue_amount = effort.due_next_time_from_start(cache) - (current_tfs + effort.start_offset)
      result << effort if effort.overdue_amount > 0
    end
    result
  end

end
