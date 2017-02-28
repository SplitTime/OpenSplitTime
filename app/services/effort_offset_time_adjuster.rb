class EffortOffsetTimeAdjuster

  # Some time data is entered based on military time, and in that case the military time
  # (as opposed to the elapsed time stored in the database) is more likely correct if the
  # two conflict. If an effort.start_offset changes but we want existing military times
  # (other than the start split_time) to remain the same, we need to counter that change
  # by subtracting a like amount in all later split_times for that effort.

  attr_reader :reports

  def self.adjust(args)
    adjuster = new(args)
    adjuster.assign_adjustments
    adjuster.save_changes
  end

  def initialize(args)
    ArgsValidator.validate(params: args,
                           required: :effort,
                           exclusive: [:effort, :split_times],
                           class: self.class)
    @effort = args[:effort]
    @split_times = args[:split_times] || effort.split_times.to_a
    @reports = []
  end

  def assign_adjustments
    start_offset_shift = effort.start_offset - effort.start_offset_was
    non_start_split_times.each { |st| st.time_from_start -= start_offset_shift }
  end

  def save_changes
    reports << BulkUpdateService.update_attributes(:split_times, changed_split_time_attributes)
    if effort.changed? && no_errors?
      reports << effort.errors.full_messages unless effort.save
    end
  end

  private

  attr_reader :effort, :split_times

  def no_errors?
    reports.none? { |report| report =~ /error/ }
  end

  def changed_split_times
    non_start_split_times.select(&:changed?)
  end

  def changed_split_time_attributes
    changed_split_times.map { |st| [st.id, {time_from_start: st.time_from_start}] }
  end

  def non_start_split_times
    @non_start_split_times ||= split_times.reject { |st| st.time_from_start.zero? }
  end
end