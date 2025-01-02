class CourseBestEffortsController < ApplicationController
  before_action :authenticate_user!, except: [:index]
  before_action :set_organization
  before_action :set_course

  # GET /organizations/:organization_id/courses/:course_id/best_efforts
  def index
    @presenter = ::CourseBestEffortsDisplay.new(@course, view_context)

    respond_to do |format|
      format.html
      format.turbo_stream
    end
  end

  private

  def params_class
    ::CourseBestEffortParameters
  end

  def set_organization
    @organization = ::Organization.friendly.find(params[:organization_id])
  end

  def set_course
    @course = @organization.courses.friendly.find(params[:course_id])
  end
end
