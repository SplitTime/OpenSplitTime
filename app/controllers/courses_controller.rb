class CoursesController < ApplicationController
  before_action :authenticate_user!, except: [:index, :show, :best_efforts, :plan_effort]
  before_action :set_course, except: [:index, :new, :create]
  before_action :set_event_group, only: [:update]
  after_action :verify_authorized, except: [:index, :show, :best_efforts, :plan_effort]

  def index
    @courses = Course.paginate(page: params[:page], per_page: 25).order(:name)
    session[:return_to] = courses_path
  end

  def show
    course = Course.where(id: @course).includes(:splits).first
    @presenter = CoursePresenter.new(course, params, current_user)
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
      respond_to do |format|
        format.json { render json: {success: true, id: @course.id, type: 'course'}, status: :created }
      end
    else
      respond_to do |format|
        format.json { render json: {success: false, errors: jsonapi_error_object(@course)}, status: :unprocessable_entity }
      end
    end
  end

  def update
    authorize @course

    if @course.update(permitted_params)
      redirect_to staging_redirect_path
    else
      @form = StagingForm.new(event_group: @event_group, step: :courses, course: @course, current_user: current_user)
      render 'event_groups/courses'
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
      @presenter = BestEffortsDisplay.new(@course, prepared_params)
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
    @course = Course.friendly.find(params[:id])

    if request.path != course_path(@course)
      redirect_numeric_to_friendly(@course, params[:id])
    end
  end

  def set_event_group
    @event_group = EventGroup.friendly.find(params[:event_group_id])
  end

  def staging_redirect_path
    case params[:button]
    when 'Continue'
      roster_event_group_path(@event_group)
    when 'Previous'
      edit_event_path(@event_group.events.where(course_id: @course.id).first)
    when 'Save'
      courses_event_group_path(@event_group, course_id: @course.id)
    else
      course_path(@course)
    end
  end
end
