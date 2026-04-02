class EffortProgressSummary < EffortProgressRow
  def post_initialize(args)
    raise ArgumentError, "effort_progress_summary must include effort" unless args[:effort]
    raise ArgumentError, "effort_progress_summary must include event_framework" unless args[:event_framework]
  end

  def seconds_past_due
    return nil unless minutes_past_due

    minutes_past_due * 1.minute
  end

  def minutes_past_due
    @minutes_past_due ||= next_absolute_time && ((Time.current - next_absolute_time) / 1.minute).round
  end

  def past_due?
    return false unless minutes_past_due

    minutes_past_due >= past_due_threshold
  end

  delegate :past_due_threshold, to: :event_framework
end
