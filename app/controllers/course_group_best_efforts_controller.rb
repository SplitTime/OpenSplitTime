# frozen_string_literal: true

class CourseGroupBestEffortsController < ApplicationController
  before_action :authenticate_user!, except: [:index]
  before_action :set_course_group
  before_action :set_organization
  after_action :verify_authorized, except: [:index]

  def index
    @presenter = ::CourseGroupBestEffortsDisplay.new(@course_group, view_context)

    respond_to do |format|
      format.html
      format.json do
        segments = @presenter.filtered_segments
        html = params[:html_template].present? ? render_to_string(partial: params[:html_template], formats: [:html], collection: segments) : ""
        render json: {best_effort_segments: segments, html: html, links: {next: @presenter.next_page_url}}
      end
    end
  end

  def export_async
  end

  private

  def set_course_group
    @course_group = ::CourseGroup.friendly.find(params[:course_group_id])
  end

  def set_organization
    @organization = ::Organization.friendly.find(params[:organization_id])
  end
end
