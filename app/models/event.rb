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

  def associated_split_times(split)
    split.split_times.where(effort_id: efforts.pluck(:id))
  end

  def time_hashes(with_status = false)
    result_hash = {}
    status_hash = {} if with_status
    split_ids = splits.pluck(:id)
    split_time_hash = SplitTime.where(split_id: split_ids).pluck_to_hash(:split_id, :effort_id, :time_from_start, :data_status).group_by { |row| row[:split_id] }
    split_ids.each do |split_id|
      result_hash[split_id] = Hash[split_time_hash[split_id].map { |row| [row[:effort_id], row[:time_from_start]] }]
      status_hash[split_id] = Hash[split_time_hash[split_id].map { |row| [row[:effort_id], row[:data_status]] }] if with_status
    end
    if with_status
      return result_hash, status_hash
    else
      result_hash
    end
  end

end
