class Event < ActiveRecord::Base
  include Auditable
  include SplitMethods
  include StatisticalMethods
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
        @exact_match.pull_data_from_effort(effort.id)
      end
    end
  end

  def assign_participants_to_efforts(id_hash)
    id_hash.each { |effort_id, participant_id| assign_participant_to_effort(effort_id, participant_id) }
  end

  def assign_participant_to_effort(effort_id, participant_id)
    @participant = Participant.find(participant_id)
    @participant.pull_data_from_effort(effort_id)
  end

  def reconciled_efforts
    efforts.where(participant_id: !nil)
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

  def set_data_status_quick
    tfs_stats = tfs_stats_hash
    st_stats = st_stats_hash
    splits.each do |split|
      next if split.start?
      tfs_time_hash = Hash[associated_split_times(split).pluck(:effort_id, :time_from_start)]
      status_hash = tfs_time_hash.merge(tfs_stats) { |_,v,params| Event.compare_and_get_status(v,params) }
      st_time_hash = Hash[]

    end
  end

  def tfs_stats_hash
    splits.includes(:split_times).load
    result = {}
    splits.each do |split|
      result[split.id] = Event.low_and_high_params(split.split_times.pluck(:time_from_start))
    end
    result.compact
  end

  def st_stats_hash
    result = {}
    splits.each do |split|
      previous = previous_split(split)
      st_data_array = previous ? split.course.segment_time_data_array(previous, split).values : []
      result[split.id] = Event.low_and_high_params(st_data_array)
    end
    result.compact
  end

  def associated_split_times(split)
    split.split_times.where(effort_id: efforts.pluck(:id))
  end

end
