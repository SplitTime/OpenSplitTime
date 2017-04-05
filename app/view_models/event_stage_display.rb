class EventStageDisplay < EventWithEffortsPresenter

  attr_reader :associated_splits
  delegate :id, :unreconciled_efforts, :unreconciled_efforts?, :started?, to: :event

  def post_initialize(args)
    @associated_splits = event.ordered_splits
  end

  def filtered_efforts
    @filtered_efforts ||= scoped_efforts
                              .search(params[:search])
                              .order(params[:sort])
                              .paginate(page: params[:page], per_page: 25)
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

  def view_text
    %w(splits efforts problems).include?(params[:view]) ? params[:view] : 'efforts'
  end

  private

  def scoped_efforts
    params[:view] == 'problems' ? event_efforts.invalid_status : event_efforts
  end
end
