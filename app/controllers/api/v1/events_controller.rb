class Api::V1::EventsController < ApiController
  before_action :set_event, except: :create

  def show
    authorize @event
    render json: @event
  end

  def create
    event = Event.new(event_params)
    authorize event

    if event.save
      render json: {message: 'event created', event: event}
    else
      render json: {message: 'event not created', error: "#{event.errors.full_messages}"}, status: :bad_request
    end
  end

  def update
    authorize @event
    if @event.update(event_params)
      render json: {message: 'event updated', event: @event}
    else
      render json: {message: 'event not updated', error: "#{@event.errors.full_messages}"}, status: :bad_request
    end
  end

  def destroy
    authorize @event
    if @event.destroy
      render json: {message: 'event destroyed', event: @event}
    else
      render json: {message: 'event not destroyed', error: "#{@event.errors.full_messages}"}, status: :bad_request
    end
  end

  private

  def set_event
    @event = Event.find_by(id: params[:id])
    render json: {message: 'event not found'}, status: :not_found unless @event
  end

  def event_params
    params.require(:event).permit(:id, :course_id, :organization_id, :name, :start_time, :concealed,
                                  :available_live, :beacon_url, :laps_required, :staging_id)
  end
end