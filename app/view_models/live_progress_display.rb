class LiveProgressDisplay < LiveEventFramework
  attr_reader :times_container, :past_due_threshold

  def post_initialize(args)
    @past_due_threshold = args[:past_due_threshold].presence.try(:to_i) || 30
    validate_setup
  end

  def past_due_progress_rows
    progress_rows.select(&:past_due?).sort_by { |row| -row.minutes_past_due }
  end

  def efforts_past_due_count
    past_due_progress_rows.size
  end

  private

  def progress_rows
    @progress_rows ||= event_efforts.select(&:in_progress?).map do |effort|
      EffortProgressSummary.new(effort: effort, event_framework: self)
    end
  end

  def validate_setup
    raise ArgumentError, "live_progress_display must include event" unless event
  end
end
