class LiveProgressReport < LiveEventFramework

  attr_reader :past_due_threshold

  def post_initialize(args)
    ArgsValidator.validate(params: args, required: :event,
                           exclusive: [:event, :past_due_threshold, :times_container],
                           class: self.class)
    @past_due_threshold = args[:past_due_threshold].presence.try(:to_i) || 30
  end

  def past_due_progress_rows
    progress_rows.select(&:past_due?).sort_by { |row| -row.minutes_past_due }
  end

  def efforts_past_due_count
    past_due_progress_rows.size
  end

  private

  def progress_rows
    @progress_rows ||= efforts.select(&:in_progress?).map do |effort|
      EffortProgressRow.new(effort: effort, event_framework: self)
    end
  end
end