class CourseGroupFinishersController < ApplicationController
  before_action :authenticate_user!, except: [:index, :show]
  before_action :set_course_group
  before_action :set_organization

  # GET /organizations/:organization_id/course_groups/:course_group_id/finishers
  def index
    @presenter = ::CourseGroupFinishersDisplay.new(@course_group, view_context)

    respond_to do |format|
      format.html
      format.turbo_stream
    end
  end

  # GET /organizations/:organization_id/course_groups/:course_group_id/finishers/:id
  def show
    course_group_finisher = ::CourseGroupFinisher.for_course_groups(@course_group).find_by!(slug: params[:id])
    @presenter = ::CourseGroupFinisherPresenter.new(course_group_finisher)
  end

  # POST /organizations/:organization_id/course_groups/:course_group_id/finishers/export_async
  def export_async
    @presenter = ::CourseGroupFinishersDisplay.new(@course_group, view_context)
    uri = URI(request.referrer)
    source_url = [uri.path, uri.query].compact.join("?")
    sql_string = @presenter.filtered_finishers_unpaginated.to_sql

    export_job = current_user.export_jobs.new(
      controller_name: controller_name,
      resource_class_name: "CourseGroupFinisher",
      source_url: source_url,
      sql_string: sql_string,
      status: :waiting,
    )

    if export_job.save
      ::ExportAsyncJob.perform_later(export_job.id)
      flash[:success] = "Export in progress."
      redirect_to export_jobs_path
    else
      flash[:danger] = "Unable to create export job: #{export_job.errors.full_messages.join(', ')}"
      redirect_to request.referrer || export_jobs_path, status: :unprocessable_entity
    end
  end

  private

  def params_class
    ::CourseGroupFinisherParameters
  end

  def set_course_group
    @course_group = ::CourseGroup.friendly.find(params[:course_group_id])
  end

  def set_organization
    @organization = ::Organization.friendly.find(params[:organization_id])
  end
end
