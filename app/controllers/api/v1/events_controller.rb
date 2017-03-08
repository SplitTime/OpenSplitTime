class Api::V1::EventsController < ApiController
  before_action :set_event, except: :create

  # GET /api/v1/events/:staging_id
  def show
    authorize @event
    render json: @event, include: params[:include]
  end

  # POST /api/v1/events
  def create
    event = Event.new(event_params)
    authorize event

    if event.save
      event.reload
      render json: event, status: :created
    else
      render json: {message: 'event not created', error: "#{event.errors.full_messages}"}, status: :bad_request
    end
  end

  # PUT /api/v1/events/:staging_id
  def update
    authorize @event
    if @event.update(event_params)
      render json: @event
    else
      render json: {message: 'event not updated', error: "#{@event.errors.full_messages}"}, status: :bad_request
    end
  end

  # DELETE /api/v1/events/:staging_id
  def destroy
    authorize @event
    if @event.destroy
      render json: @event
    else
      render json: {message: 'event not destroyed', error: "#{@event.errors.full_messages}"}, status: :bad_request
    end
  end

  # GET /api/v1/events/:staging_id/spread
  def spread
    authorize @event
    params[:display_style] ||= 'absolute'
    spread_display = EventSpreadDisplay.new(@event, params.slice(:display_style, :sort))
    render json: spread_display, serializer: EventSpreadSerializer, include: 'effort_times_rows'
  end

  # PUT /api/v1/events/:staging_id/associate_splits?split_ids=[x, y, ...]
  def associate_splits
    authorize @event
    proposed_splits = Split.where(id: params[:split_ids])
    if proposed_splits.present?
      added_splits = proposed_splits - @event.splits
      if added_splits.present?
        if @event.splits << added_splits
          render json: {message: 'splits associated with event', splits: added_splits}, status: :created
        else
          render json: {message: 'splits not associated with event'}, status: :bad_request
        end
      else
        render json: {message: 'splits already associated with event', splits: proposed_splits}
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

  # Send 'with_times' => 'false' to ignore split_time data
  # Send 'time_format' => 'elapsed' or 'military' depending on time data format
  # Send 'with_status' => 'false' to skip setting data status for imported split_times

  # POST /api/v1/events/:staging_id/import_efforts
  def import_efforts
    authorize @event
    file_url = BucketStoreService.upload_to_bucket('imports', params[:file], current_user.id)
    if file_url
      if (Rails.env == 'development') || (Rails.env == 'test')
        ImportEffortsJob.perform_now(file_url, @event, current_user.id, params.slice(:time_format, :with_times, :with_status))
        render json: {message: 'Import complete.'}
      else
        ImportEffortsJob.perform_later(file_url, @event, current_user.id, params.slice(:time_format, :with_times, :with_status))
        render json: {message: 'Import in progress.'}
      end
    else
      render json: {message: 'Import file too large.'}, status: :bad_request
    end
  end

  private

  def set_event
    @event = params[:staging_id].uuid? ?
        Event.find_by!(staging_id: params[:staging_id]) :
        Event.friendly.find(params[:staging_id])
  end

  def event_params
    params.require(:event).permit(*Event::PERMITTED_PARAMS)
  end
end
