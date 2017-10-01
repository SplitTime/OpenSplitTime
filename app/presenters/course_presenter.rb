class CoursePresenter < BasePresenter

  attr_reader :course, :events
  delegate :id, :name, :description, :ordered_splits, :simple?, to: :course

  def initialize(course, params, current_user)
    @course = course
    @params = params
    @current_user = current_user
    @events = course.events.select_with_params(params[:search]).order(start_time: :desc).to_a
  end

  def course_has_location_data?
    ordered_splits.any? { |split| split.latitude && split.longitude }
  end

  def display_style
    params[:display_style] == 'splits' ? 'splits' : 'events'
  end

  def latitude_center
    ordered_splits.map(&:latitude).compact.mean
  end

  def longitude_center
    ordered_splits.map(&:longitude).compact.mean
  end

  def show_visibility_columns?
    current_user&.admin?
  end

  def default_zoom
    9
  end

  private

  attr_reader :params, :current_user
end
