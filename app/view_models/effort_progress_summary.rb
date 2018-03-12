# frozen_string_literal: true

class EffortProgressSummary < EffortProgressRow

  def post_initialize(args)
    ArgsValidator.validate(params: args,
                           required: [:effort, :event_framework],
                           exclusive: [:effort, :event_framework],
                           class: self.class)
  end

  def seconds_past_due
    minutes_past_due * 1.minute
  end

  def minutes_past_due
    @minutes_past_due ||= effort.day_and_time(time_from_start_to_next) && ((Time.current - effort.day_and_time(time_from_start_to_next)) / 1.minute).round
  end

  def past_due?
    minutes_past_due && (minutes_past_due >= past_due_threshold)
  end

  private

  delegate :past_due_threshold, to: :event_framework
end
