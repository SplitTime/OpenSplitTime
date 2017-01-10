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

  validates_presence_of :course_id, :name, :start_time, :laps_required
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
                                                     .group("events.id").order(start_time: :desc) }

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
    unreconciled_efforts.present?
  end

  def set_all_course_splits
    splits << course.splits
  end

  def split_times
    SplitTime.includes(:effort).where(efforts: {event_id: id})
  end

  def combined_places(effort)
    [overall_place(effort), gender_place(effort)]
  end

  def overall_place(effort)
    effort_places[effort.id].try(:overall_rank)
  end

  def gender_place(effort)
    effort_places[effort.id].try(:gender_rank)
  end

  def sub_splits
    ordered_splits.map(&:sub_splits).flatten
  end

  def course_name
    course.name
  end

  def race_name
    race.try(:name)
  end

  def started?
    SplitTime.where(effort: efforts).present?
  end

  def set_dropped_attributes
    BulkUpdateService.set_dropped_attributes(outdated_dropped_attributes)
  end

  def outdated_dropped_attributes
    efforts_sorted.map { |effort| dropped_attributes(effort) }
  end

  private

  def dropped_attributes(effort)
    if effort.finished
      update_hash[effort.id] = {} if effort.dropped_split_id || effort.dropped_lap
    else
      update_hash[effort.id] = {lap: effort.final_lap, split_id: effort.final_split_id} if
          (effort.final_split_id != effort.dropped_split_id) || (effort.final_lap != effort.dropped_lap)
    end
  end

  def efforts_sorted
    @efforts_sorted ||= efforts.sorted_with_finish_status
  end

  def effort_places
    @effort_places ||= efforts.sorted_with_finish_status(effort_fields: 'id').index_by(&:id)
  end
end