class Api::V1::StagingController < ApiController
  before_action :set_event, except: [:post_event_course_org, :get_countries, :get_time_zones]
  before_action :authorize_event, except: [:post_event_course_org, :get_countries, :get_time_zones]

  # GET /api/v1/staging/get_countries
  def get_countries
    authorize Event
    render json: {countries: Geodata.standard_countries_subregions}
  end

  # GET /api/v1/staging/get_time_zones
  def get_time_zones
    authorize Event
    render json: {time_zones: ActiveSupport::TimeZone.all.map { |tz| [tz.name, tz.formatted_offset]} }
  end

  # Returns location data for all splits on any course that falls
  # entirely or partially within the provided boundaries, but excludes splits on
  # the course of the provided event.

  # GET /api/vi/staging/:staging_id/get_locations?west=&east=&south=&north=
  def get_locations
    splits = SplitLocationFinder.splits(params).where.not(course_id: @event.course_id)
    render json: splits, each_serializer: SplitLocationSerializer
  end

  # Creates or updates the given event, course, and organization
  # and associates the event with the course and organization,
  # all in a single transaction.

  # POST /api/v1/staging/:staging_id/post_event_course_org
  def post_event_course_org
    event = params[:staging_id] == 'new' ? Event.new : Event.friendly.find(params[:staging_id])
    course = Course.find_or_initialize_by(id: params.dig(:course, :id))
    organization = Organization.find_or_initialize_by(id: params.dig(:organization, :id))

    skip_authorization if event.new_record? && course.new_record? && organization.new_record?
    authorize event unless event.new_record?
    authorize course unless course.new_record?
    authorize organization unless organization.new_record?

    setter = EventCourseOrgSetter.new(event: event, course: course, organization: organization, params: params)
    setter.set_resources
    if setter.status == :ok
      render json: setter.resources.map { |resource| [resource.class.to_s.underscore, resource] }.to_h, status: setter.status
    else
      render json: {errors: setter.resources.map { |resource| jsonapi_error_object(resource) }}, status: setter.status
    end
  end

  # Sets the concealed status of the event and related organization, efforts, and people.
  # param :status must be set to 'public' or 'private'

  # PATCH /api/v1/staging/:staging_id/update_event_visibility
  def update_event_visibility
    setter = EventConcealedSetter.new(event: @event)
    if params[:status] == 'public'
      setter.make_public
    elsif params[:status] == 'private'
      setter.make_private
    else
      render json: {errors: ['invalid status'], detail: 'request must include status: public or status: private'}, status: :bad_request and return
    end
    render json: setter.response, status: setter.status
  end

  private

  def set_event
    @event = params[:staging_id].uuid? ?
        Event.find_by!(staging_id: params[:staging_id]) :
        Event.friendly.find(params[:staging_id])
  end

  def authorize_event
    authorize @event
  end
end
