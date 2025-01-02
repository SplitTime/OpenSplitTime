class CourseGroupBestEffortsController < ApplicationController
  before_action :authenticate_user!, except: [:index]
  before_action :set_course_group
  before_action :set_organization

  # GET /organizations/:organization_id/course_groups/:course_group_id/best_efforts
  def index
    @presenter = ::CourseGroupBestEffortsDisplay.new(@course_group, view_context)

    respond_to do |format|
      format.html
      format.turbo_stream
    end
  end

  # POST /organizations/:organization_id/course_groups/:course_group_id/best_efforts/export_async
  def export_async
    @presenter = ::CourseGroupBestEffortsDisplay.new(@course_group, view_context)
    uri = URI(request.referrer)
    source_url = [uri.path, uri.query].compact.join("?")
    sql_string = @presenter.filtered_segments_unpaginated.finish_count_subquery.to_sql

    export_job = current_user.export_jobs.new(
      controller_name: controller_name,
      resource_class_name: "BestEffortSegment",
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
    ::CourseGroupBestEffortParameters
  end

  def set_course_group
    @course_group = ::CourseGroup.friendly.find(params[:course_group_id])
  end

  def set_organization
    @organization = ::Organization.friendly.find(params[:organization_id])
  end
end
