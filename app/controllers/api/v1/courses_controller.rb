class Api::V1::CoursesController < ApiController
  before_action :set_course, except: :create

  def show
    authorize @course
    render json: @course
  end

  def create
    course = Course.new(course_params)
    authorize course

    if course.save
      render json: {message: 'course created', course: course}
    else
      render json: {message: 'course not created', error: "#{course.errors.full_messages}"}, status: :bad_request
    end
  end

  def update
    authorize @course
    if @course.update(course_params)
      render json: {message: 'course updated', course: @course}
    else
      render json: {message: 'course not updated', error: "#{@course.errors.full_messages}"}, status: :bad_request
    end
  end

  def destroy
    authorize @course
    if @course.destroy
      render json: {message: 'course destroyed', course: @course}
    else
      render json: {message: 'course not destroyed', error: "#{@course.errors.full_messages}"}, status: :bad_request
    end
  end

  private

  def set_course
    @course = Course.find_by(id: params[:id])
    render json: {message: 'course not found'}, status: :not_found unless @course
  end

  def course_params
    params.require(:course).permit(Course::PERMITTED_PARAMS)
  end
end