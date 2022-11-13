# frozen_string_literal: true

class CourseGroupBestEffortsController < ApplicationController
  before_action :authenticate_user!, except: [:index]
  before_action :set_course_group
  before_action :set_organization
  after_action :verify_authorized, except: [:index]

  # GET /organizations/:organization_id/course_groups/:course_group_id/best_efforts
  def index
    @presenter = ::CourseGroupBestEffortsDisplay.new(@course_group, view_context)

    respond_to do |format|
      format.html
      format.json do
        segments = @presenter.filtered_segments
        html = params[:html_template].present? ? render_to_string(partial: params[:html_template], formats: [:html], collection: segments) : ""
        render json: { best_effort_segments: segments, html: html, links: { next: @presenter.next_page_url } }
      end
    end
  end

  # POST /organizations/:organization_id/course_groups/:course_group_id/best_efforts/export_async
  def export_async
    authorize @organization

    @presenter = ::CourseGroupBestEffortsDisplay.new(@course_group, view_context)
    sql_string = @presenter.filtered_segments_unpaginated.to_sql

    ::ExportAsyncJob.perform_later(current_user.id, controller_name, "BestEffortSegment", sql_string)

    flash[:success] = "Export in progress; your report will be available on the Reports page when finished."
    redirect_to request.referrer || user_exports_path
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
