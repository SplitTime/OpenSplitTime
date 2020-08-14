class CoursesController < ApplicationController
  before_action :authenticate_user!, except: [:show, :best_efforts, :plan_effort]
  before_action :set_course, except: [:index, :new, :create]
  after_action :verify_authorized, except: [:show, :best_efforts, :plan_effort]

  def index
    authorize Course

    @courses = policy_scope(Course).includes(:events, :splits).with_attached_gpx.order(:name).paginate(page: params[:page], per_page: 25)
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
    # If someone tries to use a segment with the same begin and end split,
    # just null them both out (which results in start/finish)
    if params[:split1].present? && params[:split1] == params[:split2]
      params[:split1] = params[:split2] = nil
    end

    @presenter = BestEffortsDisplay.new(@course, view_context)

    respond_to do |format|
      format.html
      format.json do
        segments = @presenter.filtered_segments
        html = params[:html_template].present? ? render_to_string(partial: params[:html_template], formats: [:html], locals: {segments: segments}) : ""
        render json: {best_effort_segments: segments, html: html, links: {next: @presenter.next_page_url}}
      end
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
