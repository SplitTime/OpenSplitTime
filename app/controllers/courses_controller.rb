class CoursesController < ApplicationController
  before_action :authenticate_user!, except: [:index, :show, :best_efforts, :plan_effort]
  before_action :set_course, except: [:index, :new, :create]
  after_action :verify_authorized, except: [:index, :show, :best_efforts, :plan_effort]

  def index
    @courses = policy_scope(Course).paginate(page: params[:page], per_page: 25).order(:name)
    session[:return_to] = courses_path
  end

  def show
    course = Course.where(id: @course).includes(:splits).first
    respond_to do |format|
      format.html do
        @presenter = CoursePresenter.new(course, params, current_user)
        session[:return_to] = course_path(@course)
      end
      format.json do
        render json: course
      end
    end
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
      redirect_to courses_path
    else
      render 'new'
    end
  end

  def update
    authorize @course

    if @course.update(permitted_params)
      redirect_to @course, notice: 'Course updated'
    else
      render 'edit'
    end
  end

  def destroy
    authorize @course

    if @course.destroy
      flash[:success] = 'Course deleted.'
      redirect_to organizations_path
    else
      flash[:danger] = @course.errors.full_messages.join("\n")
      redirect_to course_path(@course)
    end
  end

  def best_efforts
    if params[:split1] && params[:split2] && params[:split1] == params[:split2]
      flash[:warning] = 'Select two different splits'
      redirect_to request.params.merge(split1: nil, split2: nil)
    elsif @course.visible_events.empty?
      flash[:danger] = 'No events yet held on this course'
      redirect_to course_path(@course)
    elsif Effort.visible.on_course(@course).empty?
      flash[:danger] = 'No efforts yet run on this course'
      redirect_to course_path(@course)
    else
      @presenter = BestEffortsDisplay.new(@course, prepared_params, current_user)
      session[:return_to] = best_efforts_course_path(@course)
    end
  end

  def plan_effort
    if @course.visible_events.empty?
      flash[:danger] = 'No events yet held on this course'
      redirect_to course_path(@course)
    else
      @presenter = PlanDisplay.new(course: @course, params: params)
      respond_to do |format|
        format.html do
          session[:return_to] = plan_effort_course_path(@course)
        end
        format.csv do
          csv_stream = render_to_string(partial: 'plan.csv.ruby')
          filename = "#{@course.name}-pacing-plan-#{@presenter.cleaned_time}-#{Date.today}.csv"
          send_data(csv_stream, type: 'text/csv', filename: filename)
        end
      end
    end
  end

  private

  def set_course
    @course = policy_scope(Course).friendly.find(params[:id])

    if request.path != course_path(@course)
      redirect_numeric_to_friendly(@course, params[:id])
    end
  end
end
