class EffortDroppedAttributesSetter

  def self.set_attributes(args)
    setter = new(args)
    setter.set_attributes
    setter.save_changes
  end

  def initialize(args)
    ArgsValidator.validate(params: args,
                           required: :effort,
                           exclusive: [:effort, :event, :ordered_split_times],
                           class: self.class)
    @effort = args[:effort]
    @event = args[:event] || effort.event
    @ordered_split_times = args[:ordered_split_times] || effort.ordered_split_times
  end

  def set_attributes
    effort.dropped_lap = dropped_time_point.lap
    effort.dropped_split_id = dropped_time_point.split_id
  end

  def save_changes
    effort.save if effort.changed?
  end

  private

  attr_reader :effort, :event, :ordered_split_times

  def dropped_time_point
    effort_not_dropped? ? TimePoint.new : last_time_point
  end

  def effort_not_dropped?
    effort_not_started? || effort_finished? || laps_unlimited?
  end

  def effort_not_started?
    ordered_split_times.empty?
  end

  def effort_finished?
    last_time_point == finish_time_point
  end

  def laps_unlimited?
    laps_required.zero?
  end

  def laps_required
    @laps_required ||= event.laps_required
  end

  def last_time_point
    @last_time_point ||= ordered_split_times.last.time_point
  end

  def finish_time_point
    @finish_time_point ||= event.time_points.last
  end
end