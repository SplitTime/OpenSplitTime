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
    render json: {time_zones: ActiveSupport::TimeZone.all.map { |tz| [tz.name, tz.formatted_offset] }}
  end

  # Returns location data for all splits on any course that falls
  # entirely or partially within the provided boundaries, but excludes splits on
  # the course of the provided event.

  # GET /api/vi/staging/:id/get_locations?west=&east=&south=&north=
  def get_locations
    splits = SplitLocationFinder.splits(params).where.not(course_id: @event.course_id)
    render json: splits, each_serializer: SplitLocationSerializer
  end

  # Creates or updates the given event, course, and organization
  # and associates the event with the course and organization,
  # all in a single transaction.

  # POST /api/v1/staging/:id/post_event_course_org
  def post_event_course_org
    event = params[:id] == 'new' ? Event.new : Event.friendly.find(params[:id])

    # This should change to params.dig(:event_group, :id) when the event-staging app supports event_groups
    event_group = EventGroup.find_or_initialize_by(id: event.event_group_id)
    course = Course.find_or_initialize_by(id: params.dig(:course, :id))
    organization = Organization.find_or_initialize_by(id: params.dig(:organization, :id))

    persisted_resources = [event, event_group, course, organization].select(&:persisted?)
    skip_authorization if persisted_resources.empty?
    persisted_resources.each { |resource| authorize resource }

    setter = EventCourseOrgSetter.new(event: event, event_group: event_group, course: course, organization: organization, params: params)
    setter.set_resources
    if setter.status == :ok
      render json: setter.resources.map { |resource| [resource.class.to_s.underscore, resource] }.to_h, status: setter.status
    else
      render json: {errors: setter.resources.map { |resource| jsonapi_error_object(resource) }}, status: setter.status
    end
  end

  # Sets the concealed status of the event and related organization and people.
  # param :status must be set to 'public' or 'private'

  # PATCH /api/v1/staging/:id/update_event_visibility
  def update_event_visibility
    if %w(public private).include?(params[:status])
      query = EventGroupQuery.set_concealed(@event.event_group_id, params[:status] == 'private')
      ActiveRecord::Base.connection.execute(query)
      render json: {errors: {}}, status: :ok
    else
      render json: {errors: ['invalid status'], detail: 'request must include status: public or status: private'}, status: :bad_request
    end
  end

  private

  def set_event
    @event = Event.friendly.find(params[:id])
  end

  def authorize_event
    authorize @event
  end
end
