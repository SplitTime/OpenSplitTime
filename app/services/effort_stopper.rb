class EffortStopper

  def self.stop(args)
    stopper = new(args)
    stopper.assign_stop
    stopper.save_changes
    stopper.report
  end

  def initialize(args)
    ArgsValidator.validate(params: args,
                           required: :effort,
                           exclusive: [:effort, :ordered_split_times, :stopped_split_time],
                           class: self.class)
    @effort = args[:effort]
    @ordered_split_times = args[:ordered_split_times] || effort.ordered_split_times.to_a
    @stopped_split_time = args[:stopped_split_time] || ordered_split_times.last
    @reports = []
    validate_setup
  end

  def assign_stop
    ordered_split_times.each { |st| st.stopped_here = (st.time_point == stopped_split_time.time_point) }
  end

  def changed_split_times
    ordered_split_times.select(&:changed?)
  end

  def save_changes
    reports << BulkUpdateService.update_attributes(:split_times, changed_split_time_attributes)
  end

  def report
    reports.join(' / ')
  end

  private

  attr_reader :effort, :ordered_split_times, :stopped_split_time, :reports

  def changed_split_time_attributes
    changed_split_times.map { |st| [st.id, {stopped_here: st.stopped_here}] }
  end

  def validate_setup
    raise ArgumentError, 'stopped_split_time is not contained within the ordered_split_times' if
        ordered_split_times.present? && ordered_split_times.exclude?(stopped_split_time)
    raise ArgumentError, 'one or more ordered_split_times is not associated with the provided effort' if
        ordered_split_times.any? { |st| st.effort_id != effort.id }
  end
end