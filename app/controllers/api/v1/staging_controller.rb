class Api::V1::StagingController < ApiController
  before_action :set_event, except: [:get_event, :post_event_course_org]
  before_action :find_or_initialize_event, only: [:get_event, :post_event_course_org]
  before_action :authorize_event

  # GET /api/v1/staging/:staging_id/get_countries
  def get_countries
    render json: {countries: Geodata.standard_countries_subregions}
  end

  # Returns only those courses that the user is authorized to edit.

  # GET /api/v1/staging/:staging_id/get_organizations
  def get_courses
    render json: CoursePolicy::Scope.new(current_user, Course).editable, include: ''
  end

  # Returns the event and its related organization and efforts,
  # together with a course id and a list of split ids.
  # To get course and split information, use
  # GET /api/v1/courses/:id

  # GET /api/v1/staging/:staging_id/get_event
  def get_event
    render json: @event, serializer: GetEventSerializer
  end

  # Returns location data for all splits on any course that falls
  # entirely or partially within the provided boundaries, but excludes splits on
  # the course of the provided event.

  # GET /api/vi/staging/:staging_id/get_locations?west=&east=&south=&north=
  def get_locations
    splits = SplitLocationFinder.splits(params).where.not(course_id: @event.course_id)
    render json: splits, each_serializer: SplitLocationSerializer
  end

  # Returns only those organizations that the user is authorized to edit.

  # GET /api/v1/staging/:staging_id/get_organizations
  def get_organizations
    render json: OrganizationPolicy::Scope.new(current_user, Organization).editable
  end

  # Creates or updates the given event, course, and organization
  # And associates the event with the course and organization.

  # POST /api/v1/staging/:staging_id/post_event_course_org
  def post_event_course_org
    course = Course.find_or_initialize_by(id: params[:course][:id])
    authorize course unless course.new_record?
    organization = Organization.find_or_initialize_by(id: params[:organization][:id])
    authorize organization unless organization.new_record?
    setter = EventCourseOrgSetter.new(event: @event, course: course, organization: organization, params: params)
    setter.set_resources
    render json: setter.response, status: setter.status
  end

  def make_event_public
    setter = EventConcealedSetter.new(event: @event)
    setter.make_public
    render json: setter.response, status: setter.status
  end

  private

  def set_event
    @event = Event.find_by(staging_id: params[:staging_id])
    render json: {message: 'event not found'}, status: :not_found unless @event
  end

  def find_or_initialize_event
    @event = Event.find_or_initialize_by(staging_id: params[:staging_id])
    unless @event.staging_id
      render json: {message: 'invalid uuid', error: 'provided staging_id is not a valid uuid'}, status: :bad_request
    end
  end

  def authorize_event
    authorize @event
  end
end