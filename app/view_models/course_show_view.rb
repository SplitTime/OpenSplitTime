class CourseShowView

  attr_reader :course, :locations, :events, :ordered_splits
  delegate :name, :description, to: :course

  def initialize(course, params)
    @course = course
    @params = params
    @locations = Location.on_course(course)
    @events = course.events.select_with_params(@params[:search]).to_a
    @ordered_splits = @course.splits.includes(:course, :location).ordered if @course.splits
  end

  def course_id
    course.id
  end

  def splits_count
    ordered_splits ? ordered_splits.count : 0
  end

  def events_count
    events ? events.count : 0
  end

  def latitude_center
    locations.pluck(:latitude).mean
  end

  def longitude_center
    locations.pluck(:longitude).mean
  end

  def zoom
    10
  end

  def course_has_locations?
    locations.present?
  end

  def view_text
    params[:view] == 'splits' ? 'splits' : 'events'
  end

  private

  attr_reader :params

end