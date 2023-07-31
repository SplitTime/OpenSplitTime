# frozen_string_literal: true

class CoursesController < ApplicationController
  before_action :authenticate_user!, except: [:index, :show, :cutoff_analysis, :plan_effort]
  before_action :set_organization
  before_action :set_course, except: [:index, :new, :create]
  after_action :verify_authorized, except: [:index, :show, :cutoff_analysis, :plan_effort]

  def index
    @presenter = ::OrganizationPresenter.new(@organization, view_context)
  end

  def show
    enable_google_maps
    course = @organization.courses.where(id: @course).includes(:splits).first

    respond_to do |format|
      format.html do
        @presenter = CoursePresenter.new(course, params, current_user)
        session[:return_to] = organization_course_path(@organization, @course)
      end
      format.json do
        render json: course
      end
    end
  end

  def new
    @course = @organization.courses.new
    authorize @course
  end

  def edit
    authorize @course
  end

  def create
    @course = @organization.courses.new(permitted_params)
    authorize @course

    @event_group = ::EventGroup.friendly.find(params[:event_group_id])

    if @course.save
      if @event_group.present?
        redirect_to new_event_group_event_path(@event_group, course_id: @course.id)
      else
        redirect_to organization_courses_path(@organization)
      end
    else
      render "new", status: :unprocessable_entity
    end
  end

  def update
    authorize @course

    if @course.update(permitted_params)
      redirect_to organization_course_path(@organization, @course), notice: "Course updated"
    else
      render "edit", status: :unprocessable_entity
    end
  end

  def destroy
    authorize @course

    if @course.destroy
      redirect_to organization_courses_path(@organization), notice: "Course deleted"
    else
      flash[:danger] = @course.errors.full_messages.join("\n")
      redirect_to organization_course_path(@organization, @course)
    end
  end

  def cutoff_analysis
    @presenter = CourseCutoffAnalysisPresenter.new(@course, view_context)
  end

  def plan_effort
    @presenter = PlanDisplay.new(course: @course, params: params)

    respond_to do |format|
      format.html do
        flash[:warning] = "Please enter your expected finish time." if params.key?(:expected_time) && params[:expected_time].blank?
      end
      format.csv do
        csv_stream = render_to_string(partial: "plan", formats: :csv)
        filename = "#{@course.name}-pacing-plan-#{@presenter.cleaned_time}-#{Date.today}.csv"
        send_data(csv_stream, type: "text/csv", filename: filename)
      end
    end
  end

  private

  def set_course
    @course = policy_scope(@organization.courses).friendly.find(params[:id])

    if request.path != organization_course_path(@organization, @course)
      redirect_numeric_to_friendly(@course, params[:id])
    end
  end

  def set_organization
    @organization = policy_scope(::Organization).friendly.find(params[:organization_id])
  end
end
