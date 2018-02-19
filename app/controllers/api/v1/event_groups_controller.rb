class Api::V1::EventGroupsController < ApiController
  include BackgroundNotifiable
  before_action :set_resource, except: [:index, :create]

  def pull_live_time_rows

    # This endpoint searches for un-pulled live_times belonging to the event_group, selects a batch,
    # marks them as pulled, combines them into live_time_rows, and returns them
    # to the live entry page.

    # Batch size is determined by params[:page][:size]; otherwise the default number will be used.
    # If params[:force_pull] == true, live_times without a matching split_time will be pulled
    # even if they show as already having been pulled.

    authorize @resource

    if @resource.available_live
      force_pull = params[:force_pull]&.to_boolean
      live_times_default_limit = 50
      live_times_limit = (params[:page] && params[:page][:size]) || live_times_default_limit

      scoped_live_times = force_pull ? @resource.live_times.unmatched : @resource.live_times.unconsidered
      selected_live_times = scoped_live_times.order(:absolute_time, :event_id, :bib_number, :split_id, :bitkey).limit(live_times_limit)

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
