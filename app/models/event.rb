class Event < ActiveRecord::Base
  include Auditable
  include Concealable
  include SplitMethods
  strip_attributes collapse_spaces: true
  belongs_to :course
  belongs_to :race
  has_many :efforts, dependent: :destroy
  has_many :aid_stations, dependent: :destroy
  has_many :splits, through: :aid_stations

  validates_presence_of :course_id, :name, :start_time
  validates_uniqueness_of :name, case_sensitive: false

  scope :recent, -> (max) { where('start_time < ?', Time.now).order(start_time: :desc).limit(max) }
  scope :most_recent, -> { where('start_time < ?', Time.now).order(start_time: :desc).first }
  scope :latest, -> { order(start_time: :desc).first }
  scope :earliest, -> { order(:start_time).first }
  scope :name_search, -> (search_param) { where('name ILIKE ?', "%#{search_param}%") }
  scope :select_with_params, -> (search_param) { search(search_param)
                                                     .where(concealed: false)
                                                     .select("events.*, COUNT(efforts.id) as effort_count")
                                                     .joins("LEFT OUTER JOIN efforts ON (efforts.event_id = events.id)")
                                                     .group("events.id")
                                                     .order(start_time: :desc) }

  def self.search(search_param)
    return all if search_param.blank?
    name_search(search_param)
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
    effort_ids = Effort.includes(:event)
                     .where(dropped_split_id: nil, events: {course_id: course_id})
                     .order('events.start_time DESC')
                     .limit(200).ids
    complete_hash = SplitTime.valid_status
                        .basic_components
                        .where(split_id: split_ids, effort_id: effort_ids)
                        .group_by(&:sub_split)
    complete_hash.keys.each do |sub_split|
      result_hash[sub_split] = Hash[complete_hash[sub_split].map { |split_time| [split_time.effort_id, split_time.time_from_start] }]
    end
    result_hash
  end

  def split_times
    SplitTime.includes(:effort).where(efforts: {event_id: id})
  end

  def split_time_hash
    split_times.group_by(&:sub_split)
  end

  def efforts_sorted
    efforts.sorted_with_finish_status
  end

  def ids_sorted
    efforts_sorted.map(&:id)
  end

  def combined_places(effort)
    found_effort = efforts_sorted.find { |e| e.id == effort.id }
    [found_effort && found_effort.overall_place, found_effort && found_effort.gender_place]
  end

  def overall_place(effort)
    combined_places(effort)[0]
  end

  def gender_place(effort)
    combined_places(effort)[1]
  end

  def sub_splits
    ordered_splits.map(&:sub_splits).flatten
  end

  def course_name
    course.name
  end

  def race_name
    race && race.name
  end

  def started?
    SplitTime.where(effort: efforts).present?
  end

  def set_dropped_split_ids
    finish_split_id = ordered_splits.last.id
    efforts = efforts_sorted # Includes final_split_id for each effort
    update_hash = {}
    efforts.each do |effort|
      if (effort.final_split_id == finish_split_id) && effort.dropped_split_id.present?
        update_hash[effort.id] = nil
      end
      if (effort.final_split_id != finish_split_id) && (effort.final_split_id != effort.dropped_split_id)
        update_hash[effort.id] = effort.final_split_id
      end
    end
    BulkUpdateService.set_dropped_split_ids(update_hash)
  end
end