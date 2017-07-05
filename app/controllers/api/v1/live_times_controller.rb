class Api::V1::LiveTimesController < ApiController
  before_action :set_resource, except: [:index, :pull, :create]

  def pull
    event = Event.friendly.find(params[:staging_id])
    authorize event

    force_pull = false
    scoped_live_times = force_pull ? event.live_times.unmatched : event.live_times.unconsidered
    live_times = scoped_live_times.order(:split_id, :bib_number, :bitkey)
    paginate json: live_times
    live_times.update_all(pulled_by: current_user.id, pulled_at: Time.current)
  end
end
