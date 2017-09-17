class EventStageDisplay < EventWithEffortsPresenter

  attr_reader :associated_splits
  delegate :id, :unreconciled_efforts, :unreconciled_efforts?, :started?, :partners, :live_times, to: :event

  def post_initialize(args)
    @associated_splits ||= event.ordered_splits.to_a
  end

  def filtered_efforts
    @filtered_efforts ||= scoped_efforts
                              .search(search_text)
                              .where(filter_hash)
                              .order(sort_hash)
                              .select { |effort| matches_criteria?(effort) }
                              .paginate(page: page, per_page: per_page)
  end

  def filtered_efforts_count
    filtered_efforts.total_entries
  end

  def event_splits_count
    associated_splits.size
  end

  def course_splits
    course.splits
  end

  def course_splits_count
    course_splits.size
  end

  def ready_efforts_count
    ready_efforts.size
  end

  def ready_efforts
    @ready_efforts ||= event_efforts.ready_to_start
  end

  def filtered_live_times
    @filtered_live_times ||= live_times
                                 .with_split_names
                                 .where(filter_hash)
                                 .order(sort_hash.presence || {created_at: :desc})
                                 .paginate(page: page, per_page: per_page)
  end

  def display_style
    %w(splits efforts problems partners times).include?(params[:display_style]) ? params[:display_style] : 'efforts'
  end

  def checked_in_filter?
    params[:checked_in]&.to_boolean
  end

  def started_filter?
    params[:started]&.to_boolean
  end

  def effort_started?(effort)
    started_effort_ids.include?(effort.id)
  end

  private

  def matches_criteria?(effort)
    matches_checked_in_criteria?(effort) && matches_start_criteria?(effort)
  end

  def matches_checked_in_criteria?(effort)
    case checked_in_filter?
    when true
      effort.checked_in
    when false
      !effort.checked_in
    else # value is nil so do not filter
      true
    end
  end

  def matches_start_criteria?(effort)
    case started_filter?
    when true
      effort_started?(effort)
    when false
      !effort_started?(effort)
    else # value is nil so do not filter
      true
    end
  end

  def scoped_efforts
    params[:display_style] == 'problems' ? event_efforts.invalid_status : event_efforts
  end
end
