class Api::V1::EventsController < ApiController
  before_action :set_event, except: :create

  # GET /api/v1/events/:staging_id
  def show
    authorize @event
    render json: @event
  end

  # POST /api/v1/events
  def create
    event = Event.new(event_params)
    authorize event

    if event.save
      event.reload
      render json: {message: 'event created', event: event}
    else
      render json: {message: 'event not created', error: "#{event.errors.full_messages}"}, status: :bad_request
    end
  end

  # PUT /api/v1/events/:staging_id
  def update
    authorize @event
    if @event.update(event_params)
      render json: {message: 'event updated', event: @event}
    else
      render json: {message: 'event not updated', error: "#{@event.errors.full_messages}"}, status: :bad_request
    end
  end

  # DELETE /api/v1/events/:staging_id
  def destroy
    authorize @event
    if @event.destroy
      render json: {message: 'event destroyed', event: @event}
    else
      render json: {message: 'event not destroyed', error: "#{@event.errors.full_messages}"}, status: :bad_request
    end
  end

  # PUT /api/v1/events/:staging_id/associate_splits?split_ids=[x, y, ...]
  def associate_splits
    authorize @event
    splits = Split.where(id: params[:split_ids])
    if splits.present?
      if @event.splits << splits
        render json: {message: 'splits associated with event', splits: splits}
      else
        render json: {message: 'splits not associated with event'}, status: :bad_request
      end
    else
      render json: {message: 'splits not found'}, status: :not_found
    end
  end

  # DELETE /api/v1/events/:staging_id/remove_splits?split_ids=[x, y, ...]
  def remove_splits
    authorize @event
    splits = Split.where(id: params[:split_ids])
    if splits.present?
      if @event.splits.delete(splits)
        render json: {message: 'splits removed from event', splits: splits}
      else
        render json: {message: 'splits not removed from event', splits: splits}, status: :bad_request
      end
    else
      render json: {message: 'splits not found'}, status: :not_found
    end
  end

  private

  def set_event
    @event = Event.find_by(staging_id: params[:staging_id])
    render json: {message: 'event not found'}, status: :not_found unless @event
  end

  def event_params
    params.require(:event).permit(:id, :course_id, :organization_id, :name, :start_time, :concealed,
                                  :available_live, :beacon_url, :laps_required, :staging_id)
  end
end