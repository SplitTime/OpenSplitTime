class EventStageDisplay

  attr_reader :event, :associated_splits
  delegate :id, :name, :start_time, :course, :race, :available_live, :simple?,
           :unreconciled_efforts, :unreconciled_efforts?, :started?, :beacon_url, to: :event

  def initialize(event, params)
    @event = event
    @params = params
    @associated_splits = event.ordered_splits
  end

  def event_efforts
    @event_efforts ||= event.efforts
  end

  def filtered_efforts
    @filtered_efforts ||= scoped_efforts
                              .search(params[:search])
                              .paginate(page: params[:page], per_page: 25)
  end

  def scoped_efforts
    params[:view] == 'problems' ? event_efforts.invalid_status : event_efforts
  end

  def efforts_count
    event_efforts.size
  end

  def filtered_efforts_count
    filtered_efforts.total_entries
  end

  def course_name
    course.name
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

  def race_name
    race.try(:name)
  end

  def view_text
    %w(splits efforts problems).include?(params[:view]) ? params[:view] : 'efforts'
  end

  private

  attr_reader :params
end