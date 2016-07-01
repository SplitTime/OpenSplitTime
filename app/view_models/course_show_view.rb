class CourseShowView

  attr_reader :course, :locations, :ordered_splits
  delegate :name, :description, to: :course

  def initialize(course)
    @course = course
    @locations = Location.on_course(course)
    @ordered_splits = @course.splits.includes(:course, :location).ordered if @course.splits
  end

  def course_id
    course.id
  end

  def split_count
    ordered_splits ? ordered_splits.count : 0
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

end