class EventStageDisplay

  attr_accessor :event_efforts, :filtered_efforts
  attr_reader :event, :associated_splits
  delegate :id, :name, :start_time, :course, :race, :available_live, :simple?, :unreconciled_efforts?, to: :event

  # initialize(event)
  # event is an ordinary event object

  def initialize(event, params)
    @event = event
    @params = params
    @associated_splits = @event.ordered_splits
    get_efforts(params)
  end

  def efforts_count
    event_efforts ? event_efforts.count : 0
  end

  def filtered_efforts_count
    filtered_efforts.total_entries
  end

  def course_name
    course.name
  end

  def event_splits_count
    associated_splits.count
  end

  def course_splits
    course.splits
  end

  def course_splits_count
    course_splits ? course_splits.count : 0
  end

  def race_name
    race ? race.name : nil
  end

  private

  attr_accessor :params

  def get_efforts(params)
    self.event_efforts = event.efforts
    self.filtered_efforts = event_efforts
                                .search(params[:search_param])
                                .paginate(page: params[:page], per_page: 25)
  end

end