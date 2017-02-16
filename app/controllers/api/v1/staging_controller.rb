class Api::V1::StagingController < ApiController
  before_action :set_event, except: [:get_event, :post_event_course_org, :get_countries]
  before_action :find_or_initialize_event, only: [:get_event, :post_event_course_org]

  # GET /api/vi/staging/:staging_id/get_locations?west=&east=&south=&north=
  def get_locations
    authorize @event
    locations = Location.bounded_by(get_locations_params.transform_values(&:to_f)).first(500)
    render json: locations
  end

  # GET /api/v1/staging/:staging_id/get_event
  def get_event
    authorize @event
    render json: @event
  end

  # GET /api/v1/staging/get_countries
  def get_countries
    authorize :event_staging, :get_countries?
    render json: {countries: Geodata.standard_countries_subregions}
  end

  # POST /api/v1/staging/:staging_id/post_event_course_org
  def post_event_course_org
    authorize @event
    course = Course.find_or_initialize_by(id: params[:course][:id])
    authorize course unless course.new_record?
    organization = Organization.find_or_initialize_by(id: params[:organization][:id])
    authorize organization unless organization.new_record?
    setter = EventCourseOrgSetter.new(event: @event, course: course, organization: organization, params: params)
    setter.set_resources
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

  def get_locations_params
    params.permit(:west, :east, :south, :north)
  end
end