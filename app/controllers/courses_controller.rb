class CoursesController < ApplicationController
  before_action :authenticate_user!, except: [:index, :show, :best_efforts, :segment_picker]
  before_action :set_course, except: [:index, :new, :create]
  after_action :verify_authorized, except: [:index, :show, :best_efforts, :segment_picker]

  def index
    @courses = Course.paginate(page: params[:page], per_page: 25).order(:name)
    session[:return_to] = courses_path
  end

  def show
    @course_view = CourseShowView.new(@course, params)
    session[:return_to] = course_path(@course)
  end

  def new
    @course = Course.new
    authorize @course
  end

  def edit
    authorize @course
  end

  def create
    @course = Course.new(permitted_params)
    authorize @course

    if @course.save
      @course.update_initial_splits
      redirect_to event_staging_app_path('new')
    else
      render 'new'
    end
  end

  def update
    authorize @course

    if @course.update(permitted_params)
      redirect_to session.delete(:return_to) || @course
    else
      render 'edit'
    end
  end

  def destroy
    authorize @course
    if @course.events.present?
      flash[:danger] = 'Course cannot be deleted if events are present on the course. ' +
          'Delete the related events individually and then delete the course.'
    else
      @course.destroy
      flash[:success] = 'Course deleted.'
    end

    session[:return_to] = params[:referrer_path] if params[:referrer_path]
    redirect_to session.delete(:return_to) || courses_path
  end

  def best_efforts
    course = Course.friendly.find(params[:id])
    if course.visible_events.empty?
      flash[:danger] = "No events yet held on this course"
      redirect_to course_path(course)
    elsif Effort.visible.on_course(course).empty?
      flash[:danger] = "No efforts yet run on this course"
      redirect_to course_path(course)
    end
    @best_display = BestEffortsDisplay.new(course, prepared_params)
    session[:return_to] = best_efforts_course_path(course)
  end

  def segment_picker
  end

  def plan_effort
    course = Course.friendly.find(params[:id])
    authorize course
    unless course.events
      flash[:danger] = "No events yet held on this course"
      redirect_to course_path(course)
    end
    @plan_display = PlanDisplay.new(course, params)
    session[:return_to] = plan_effort_course_path(course)
  end

  private

  def set_course
    @course = Course.friendly.find(params[:id])
  end
end
