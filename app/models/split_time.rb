class SplitTime < ActiveRecord::Base
  include Auditable
  include StatisticalMethods
  enum data_status: [:bad, :questionable, :good, :confirmed] # nil = unknown, 0 = bad, 1 = questionable, 2 = good, 3 = confirmed
  belongs_to :effort
  belongs_to :split

  scope :valid_status, -> { where(data_status: [nil, 2, 3]) }

  after_update :set_effort_data_status, if: :time_from_start_changed?

  validates_presence_of :effort_id, :split_id, :time_from_start
  validates :data_status, inclusion: {in: SplitTime.data_statuses.keys}, allow_nil: true
  validates_uniqueness_of :split_id, scope: :effort_id,
                          :message => "only one of any given split permitted within an effort"
  validate :course_is_consistent, unless: 'effort.nil? | split.nil?' # TODO fix tests so that .nil? checks are not necessary

  def course_is_consistent
    if effort.event.course_id != split.course_id
      errors.add(:effort_id, "the effort.event.course_id does not resolve with the split.course_id")
      errors.add(:split_id, "the effort.event.course_id does not resolve with the split.course_id")
    end
  end

  def set_effort_data_status
    effort.set_time_data_status
  end

  def set_data_status
    update(data_status: actual_data_status)
  end

  def actual_data_status # To calculate data_status for a single split_time
    tfs = tfs_data_status
    tfs == 0 ? 0 : [tfs, st_data_status(effort.previous_valid_split_time(self))].compact.min
  end

  def tfs_data_status
    solo = tfs_solo_data_status
    return 0 if solo == 0
    tfs_data_array = split.split_times.pluck(:time_from_start)
    statistical = (tfs_data_array.count >= 10) ?
        tfs_statistical_data_status(Effort.low_and_high_params(tfs_data_array)) :
        nil
    [statistical, solo].compact.min
  end

  def tfs_statistical_data_status(params) # params == [low, probably low, probably high, high]
    SplitTime.compare_and_get_status(time_from_start, params)
  end

  def tfs_solo_data_status
    velocity = tfs_velocity
    status = if (time_from_start < 0) | (time_from_start > 1.year) # To catch obviously wrong data
               'bad'
             elsif velocity < 0.1 # About 0.2 mph or 5 hours/mile
               'bad'
             elsif velocity < 0.5 # About 1 mph
               'questionable'
             elsif velocity > 15
               'bad'
             elsif velocity > 5 # 5 m/s or roughly 11 mph is a temporary flag for speed; TODO store activity type?
               'questionable'
             end
    SplitTime.data_statuses[status]
  end

  def st_data_status(split_time = nil)
    previous = split_time || previous_split_time
    distance = split.course.segment_distance(previous.split, self.split)
    time = time_from_start - previous.time_from_start
    solo = st_solo_data_status(distance, time)
    return 0 if solo == 0
    st_data_array = previous ? split.course.segment_time_data_array(previous.split, self.split).values : []
    statistical = ((st_data_array.count >= 10) && not_in_waypoint_group_with(previous)) ?
        st_statistical_data_status(distance, time, Effort.low_and_high_params(st_data_array)) :
        nil
    [statistical, solo].compact.min
  end

  def st_statistical_data_status(distance, time, params) # params == [low, probably low, probably high, high], split_time
    if distance == 0 # This is a time in aid (within a waypoint group)
      if time < 0
        SplitTime.data_statuses['bad']
      elsif time > 1.day
        SplitTime.data_statuses['questionable'] # Statistically aberrant aid station times are not necessarily wrong
      else
        SplitTime.data_statuses['good']
      end
    else # This is a 'real' segment between aid stations (waypoint groups)
      return nil unless params && params.count > 3
      SplitTime.compare_and_get_status(time, params)
    end
  end

  def st_solo_data_status(distance, time)
    status = if distance == 0 # This is a time in aid (within a waypoint group)
               (time < 0) | (time > 1.week) ? 'bad' : 'good'
             else # This is a 'real' segment between aid stations (waypoint groups)
               velocity = distance / time
               return nil if velocity.nil?
               if time < 0
                 'bad'
               elsif velocity < 0.1 # About 0.2 mph or 5 hours/mile
                 'bad'
               elsif velocity < 0.5 # About 1 mph
                 'questionable'
               elsif velocity > 15 # About 33 mph
                 'bad'
               elsif velocity > 5 # 5 m/s or roughly 11 mph is a temporary flag for speed; TODO store activity type?
                 'questionable'
               end
             end
    SplitTime.data_statuses[status]
  end

  def not_valid?
    (data_status == 'bad') | (data_status == 'questionable')
  end

  def time_as_entered
    return nil if time_from_start.nil?
    seconds = time_from_start % 60
    minutes = (time_from_start / 60) % 60
    hours = time_from_start / (60 * 60)
    format("%02d:%02d:%02d", hours, minutes, seconds)
  end

  alias_method :formatted_time_hhmmss, :time_as_entered

  def time_as_entered=(entered_time)
    units = %w(hours minutes seconds)
    self.time_from_start = entered_time.split(':').map.with_index { |x, i| x.to_i.send(units[i]) }.reduce(:+).to_i if entered_time.present?
  end

  def segment_time
    return 0 if time_from_start == 0
    effort.segment_time(split)
  end

  def segment_distance
    effort.event.segment_distance(split)
  end

  def segment_velocity
    segment_time == 0 ? 0 : (segment_distance / segment_time)
  end

  def time_from_previous_valid
    previous = previous_valid_split_time
    previous ? time_from_start - previous.time_from_start : nil
  end

  def velocity_from_previous_valid
    previous = previous_valid_split_time
    previous ? effort.segment_velocity(previous.split, self.split) : nil
  end

  def tfs_velocity
    time_from_start == 0 ? 0 : (split.distance_from_start / time_from_start)
  end

  def time_in_aid
    waypoint_group.compact.last.time_from_start - waypoint_group.compact.first.time_from_start
  end

  def previous_split_time
    effort.previous_split_time(self)
  end

  def previous_valid_split_time
    effort.previous_valid_split_time(self)
  end

  def self.ordered
    effort.ordered_split_times
  end

  def waypoint_group
    splits = split.waypoint_group
    split_time_array = []
    splits.each do |split|
      split_time_array << split.split_times.where(effort: effort).first
    end
    split_time_array # Includes nil values when no split_time is associated with members of the split.waypoint_group
  end

  def in_waypoint_group_with(other_split_time)
    split.distance_from_start == other_split_time.split.distance_from_start
  end

  def not_in_waypoint_group_with(other_split_time)
    split.distance_from_start != other_split_time.split.distance_from_start
  end

end
