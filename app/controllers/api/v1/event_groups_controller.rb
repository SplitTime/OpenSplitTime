class Api::V1::EventGroupsController < ApiController
  include BackgroundNotifiable
  before_action :set_resource, except: [:index, :create]

  def show
    authorize @resource
    event_group = EventGroup.includes(organization: :stewards, events: [:efforts, :splits]).where(id: @resource.id).first
    render json: event_group, include: prepared_params[:include], fields: prepared_params[:fields]
  end

  def pull_live_time_rows

    # This endpoint searches for un-pulled live_times belonging to the event_group, selects a batch,
    # marks them as pulled, combines them into live_time_rows, and returns them
    # to the group live entry page.

    # Batch size is determined by params[:page][:size]; otherwise the default number will be used.
    # If params[:force_pull] == true, live_times without a matching split_time will be pulled
    # even if they are marked as already having been pulled.

    authorize @resource

    if @resource.available_live
      force_pull = params[:force_pull]&.to_boolean
      live_times_default_limit = 50
      live_times_limit = (params[:page] && params[:page][:size]) || live_times_default_limit

      scoped_live_times = force_pull ? @resource.live_times.unmatched : @resource.live_times.unconsidered

      # Order should be by absolute time, and where absolute time is nil, then by entered time.
      # This ordering is important to minimize the risk of incorrectly ordered times in multi-lap events.
      selected_live_times = scoped_live_times.order(:absolute_time, :entered_time).limit(live_times_limit)

      grouped_live_times = selected_live_times.group_by(&:event_id)

      live_time_rows = grouped_live_times.map do |event_id, live_times|
        event = Event.where(id: event_id).includes(:splits, :course).first
        LiveTimeRowConverter.convert(event: event, live_times: live_times)
      end.flatten

      selected_live_times.update_all(pulled_by: current_user.id, pulled_at: Time.current)
      report_live_times_available(@resource)
      render json: {returnedRows: live_time_rows}, status: :ok
    else
      render json: live_entry_unavailable(@resource), status: :forbidden
    end
  end

  def trigger_live_times_push
    authorize @resource
    report_live_times_available(@resource)
    render json: {message: "Live times push notification sent for #{@resource.name}"}
  end
end
