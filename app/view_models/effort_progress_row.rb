class EffortProgressRow < EffortProgressFramework

  def post_initialize(args)
    ArgsValidator.validate(params: args,
                           required: [:effort, :event_framework],
                           exclusive: [:effort, :event_framework],
                           class: self.class)
  end

  def minutes_past_due
    @minutes_past_due ||= due_next_day_and_time && ((Time.current - due_next_day_and_time) / 1.minute).round
  end

  def past_due?
    minutes_past_due && (minutes_past_due >= past_due_threshold)
  end

  private

  delegate :past_due_threshold, to: :event_framework
end