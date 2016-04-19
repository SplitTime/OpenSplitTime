class SplitTime < ActiveRecord::Base
  include Auditable
  enum data_status: [:bad, :questionable, :good] # nil = unknown, 0 = bad, 1 = questionable, 2 = good
  belongs_to :effort
  belongs_to :split

  after_update :effort_data_status_reset, if: :time_from_start_changed?

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

  def effort_data_status_reset
    effort.set_data_status_vertical
    effort.set_data_status_horizontal
  end

  def time_from_start_data_status(high, probable_high, low, probable_low)
    status = if split.start?
               time_from_start == 0 ? 'good' : 'questionable'
             else
               if (time_from_start < low) | (time_from_start > high)
                 'bad'
               elsif (time_from_start < probable_low) | (time_from_start > probable_high)
                 'questionable'
               else
                 'good'
               end
             end
    SplitTime.data_statuses[status]
  end

  def segment_time_data_status(high, probable_high, low, probable_low)
    test_time = segment_time
    status = if split.start?
               time_from_start == 0 ? 'good' : 'questionable'
             elsif split.sub_order > 0 # This is a time in aid (within a waypoint group)
               if test_time < 0
                 'bad'
               elsif test_time > high
                 'questionable' # Statistically aberrant aid times are not necessarily wrong
               else
                 'good'
               end
             else # This is a 'real' segment between aid stations (waypoint groups)
               if test_time < 0
                 'bad'
               elsif (test_time < low) | (test_time > high)
                 'bad'
               elsif (test_time < probable_low) | (test_time > probable_high)
                 'questionable'
               else
                 'good'
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
    ordered_group = effort.ordered_split_times
    position = ordered_group.map(&:id).index(id)
    position == 0 ? 0 : ordered_group[position].time_from_start - ordered_group[position - 1].time_from_start
  end

  def time_in_aid
    waypoint_group.compact.last.time_from_start - waypoint_group.compact.first.time_from_start
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
