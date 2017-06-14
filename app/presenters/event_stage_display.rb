class EventStageDisplay < EventWithEffortsPresenter

  attr_reader :associated_splits
  delegate :id, :unreconciled_efforts, :unreconciled_efforts?, :started?, :partners, to: :event

  def post_initialize(args)
    @associated_splits ||= event.ordered_splits.to_a
  end

  def filtered_efforts
    @filtered_efforts ||= scoped_efforts
                              .search(search_text)
                              .where(filter_hash)
                              .order(sort_hash)
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

  def view_text
    %w(splits efforts problems partners).include?(params[:view]) ? params[:view] : 'efforts'
  end

  private

  def scoped_efforts
    params[:view] == 'problems' ? event_efforts.invalid_status : event_efforts
  end
end
