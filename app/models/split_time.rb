class SplitTime < ActiveRecord::Base
  include Auditable
  enum data_status: [:bad, :questionable, :good] # nil = unknown, 0 = bad, 1 = questionable, 2 = good
  belongs_to :effort
  belongs_to :split

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
    effort.set_time_data_status_best
  end

  def solo_data_status
    [tfs_solo_data_status, st_solo_data_status].min
  end

  def tfs_statistical_data_status(params) # params == [low, probably low, probably high, high]
    status = if split.start?
               time_from_start == 0 ? 'good' : 'bad'
             else
               if time_from_start < 0
                 'bad'
               elsif (time_from_start < params[0]) | (time_from_start > params[3])
                 'bad'
               elsif (time_from_start < params[1]) | (time_from_start > params[2])
                 'questionable'
               else
                 'good'
               end
             end
    SplitTime.data_statuses[status]
  end

  def tfs_solo_data_status
    status = if split.start?
               time_from_start == 0 ? 'good' : 'bad'
             else
               if (time_from_start < 0) | (time_from_start > 1.year) # To catch obviously wrong data
                 'bad'
               elsif tfs_velocity < 0.1 # About 0.2 mph or 5 hours/mile
                 'bad'
               elsif tfs_velocity < 0.5 # About 1 mph
                 'questionable'
               elsif tfs_velocity > 15
                 'bad'
               elsif tfs_velocity > 5 # 5 m/s or roughly 11 mph is a temporary flag for speed; TODO store activity type?
                 'questionable'
               end
             end
    SplitTime.data_statuses[status]
  end

  def st_statistical_data_status(params) # params == [low, probably low, probably high, high]
    test_time = segment_time
    status = if split.start?
               time_from_start == 0 ? 'good' : 'bad'
             elsif split.sub_order > 0 # This is a time in aid (within a waypoint group)
               if test_time < 0
                 'bad'
               elsif test_time > 1.day
                 'questionable' # Statistically aberrant aid station times are not necessarily wrong
               else
                 'good'
               end
             else # This is a 'real' segment between aid stations (waypoint groups)
               if test_time < 0
                 'bad'
               elsif (test_time < params[0]) | (test_time > params[3])
                 'bad'
               elsif (test_time < params[1]) | (test_time > params[2])
                 'questionable'
               else
                 'good'
               end
             end
    SplitTime.data_statuses[status]
  end

  def st_solo_data_status
    test_time = segment_time
    status = if split.start?
               time_from_start == 0 ? 'good' : 'bad'
             elsif split.sub_order > 0 # This is a time in aid (within a waypoint group)
               if (test_time < 0) | (test_time > 1.week) # Catch excessively long periods
                 'bad'
               end
             else # This is a 'real' segment between aid stations (waypoint groups)
               velocity = velocity_from_previous_valid
               return nil if velocity.nil?
               if test_time < 0
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

  def time_as_entered
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
    segment_distance / segment_time
  end

  def velocity_from_previous_valid
    previous = previous_valid_split_time
    previous ? effort.segment_velocity(previous.split, self.split) : nil
  end

  def tfs_velocity
    split.distance_from_start / time_from_start
  end

  def time_in_aid
    waypoint_group.compact.last.time_from_start - waypoint_group.compact.first.time_from_start
  end

  def previous_split_time
    ordered_split_times = effort.ordered_split_times
    position = ordered_split_times.index(self)
    return nil if position.nil?
    position == 0 ? nil : ordered_split_times[position - 1]

  end

  def previous_valid_split_time
    ordered_split_times = effort.ordered_valid_split_times
    position = ordered_split_times.index(self)
    return nil if position.nil?
    position == 0 ? nil : ordered_split_times[position - 1]
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

end
