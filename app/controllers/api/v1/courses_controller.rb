class Api::V1::CoursesController < ApiController
  before_action :set_course, except: [:index, :create]

  # Returns only those courses that the user is authorized to edit.
  def index
    authorize Course
    render json: CoursePolicy::Scope.new(current_user, Course).editable, include: params[:include]
  end

  def show
    authorize @course
    render json: @course, include: params[:include]
  end

  def create
    course = Course.new(permitted_params)
    authorize course

    if course.save
      render json: course, status: :created
    else
      render json: {message: 'course not created', error: "#{course.errors.full_messages}"}, status: :bad_request
    end
  end

  def update
    authorize @course
    if @course.update(permitted_params)
      render json: @course
    else
      render json: {message: 'course not updated', error: "#{@course.errors.full_messages}"}, status: :bad_request
    end
  end

  def destroy
    authorize @course
    if @course.destroy
      render json: @course
    else
      render json: {message: 'course not destroyed', error: "#{@course.errors.full_messages}"}, status: :bad_request
    end
  end

  private

  def set_course
    @course = Course.friendly.find(params[:id])
  end
end
