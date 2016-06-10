class Event < ActiveRecord::Base
  include Auditable
  include SplitMethods
  strip_attributes collapse_spaces: true
  belongs_to :course, touch: true
  belongs_to :race
  has_many :efforts, dependent: :destroy
  has_many :aid_stations, dependent: :destroy
  has_many :splits, through: :aid_stations

  validates_presence_of :course_id, :name, :start_time
  validates_uniqueness_of :name, case_sensitive: false

  scope :recent, -> (max) { order(start_time: :desc).limit(max) }
  scope :most_recent, -> { order(start_time: :desc).first }
  scope :earliest, -> { order(:start_time).first }

  def all_splits_on_course?
    splits.joins(:course).group(:course_id).count.size == 1
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

  def time_hashes_similar_events
    result_hash = {}
    split_ids = ordered_split_ids
    effort_ids = Effort.includes(:event).where(dropped_split_id: nil, events: {course_id: course_id}).order('events.start_time DESC').limit(200).pluck(:id)
    complete_hash = SplitTime.valid_status
                        .select(:split_id, :sub_split_bitkey, :effort_id, :time_from_start)
                        .where(split_id: split_ids, effort_id: effort_ids)
                        .group_by(&:bitkey_hash)
    complete_hash.keys.each do |bitkey_hash|
      result_hash[bitkey_hash] = Hash[complete_hash[bitkey_hash].map { |split_time| [split_time.effort_id, split_time.time_from_start] }]
    end
    result_hash
  end

  def split_times
    SplitTime.includes(:effort).where(efforts: {event_id: id})
  end

  def split_time_hash
    split_times.group_by(&:bitkey_hash)
  end

  def efforts_sorted
    efforts.sorted_with_finish_status
  end

  def ids_sorted
    efforts.sorted_with_finish_status.map(&:id)
  end

  def combined_places(effort)
    raw_sort = efforts_sorted
    overall_place = raw_sort.map(&:id).index(effort.id) + 1
    gender_place = raw_sort[0...overall_place].map(&:gender).count(effort.gender)
    return overall_place, gender_place
  end

  def overall_place(effort)
    ids_sorted.index(effort.id) + 1
  end

  def gender_place(effort)
    combined_places(effort)[1]
  end

  def sub_split_bitkey_hashes
    ordered_splits.map(&:sub_split_bitkey_hashes).flatten
  end

  def times_data_status(params) # Returns the status of live_entry data
    effort = efforts.where(id: params[:effortId]).first
    split_id = params[:splitId].present? ? params[:splitId].to_i : nil
    time_in_exists = nil
    time_out_exists = nil
    bitkey_hash_in = nil
    bitkey_hash_out = nil
    status_hash = {}
    if effort.present? && split_id.present?
      split_times_hash = effort.split_times.index_by(&:bitkey_hash)
      split_time_in = SplitTime.new(effort_id: effort.id,
                                    split_id: split_id,
                                    sub_split_bitkey: SubSplit::IN_BITKEY,
                                    time_from_start: params[:timeFromStartIn])
      split_time_out = SplitTime.new(effort_id: effort.id,
                                     split_id: split_id,
                                     sub_split_bitkey: SubSplit::OUT_BITKEY,
                                     time_from_start: params[:timeFromStartOut])
      bitkey_hash_in = split_time_in.bitkey_hash
      bitkey_hash_out = split_time_out.bitkey_hash
      time_in_exists = split_times_hash[bitkey_hash_in].present?
      time_out_exists = split_times_hash[bitkey_hash_out].present?
      split_times_hash[bitkey_hash_in] = split_time_in
      split_times_hash[bitkey_hash_out] = split_time_out
      ordered_bitkey_hashes = ordered_splits.to_a.map(&:sub_split_bitkey_hashes).flatten
      ordered_split_times = ordered_bitkey_hashes.collect { |key_hash| split_times_hash[key_hash] }
      status_hash = DataStatusService.live_entry_data_status(self, ordered_split_times.compact)
    end
    {success: effort.present? && split_id.present?,
     timeInExists: time_in_exists,
     timeOutExists: time_out_exists,
     timeInStatus: status_hash[bitkey_hash_in],
     timeOutStatus: status_hash[bitkey_hash_out]}
  end

end
