class Api::V1::LiveTimesController < ApiController
  before_action :set_resource, except: [:index, :pull, :create]

  def pull
    event = Event.friendly.find(params[:staging_id])
    authorize event

    live_times = event.live_times.unconsidered
    render json: live_times
    live_times.update_all(pulled_by: current_user.id, pulled_at: Time.current)
  end
end
