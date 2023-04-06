class AidStationsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_event
  before_action :authorize_organization
  after_action :verify_authorized

  def create
    @aid_station = @event.aid_stations.new(aid_station_params)

    if @aid_station.save
      split = @aid_station.split

      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace(helpers.dom_id(split, helpers.dom_id(@event)),
                                                    partial: "events/course_setup_split",
                                                    locals: { event: @event, split: split, aid_station: @aid_station })
        end
      end
    else
      redirect_to event_group_event_course_setup_path(@event.event_group, @event), status: :unprocessable_entity
    end
  end

  def destroy
    @aid_station = @event.aid_stations.find(params[:id])
    split = @aid_station.split
    @aid_station.destroy

    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream.replace(helpers.dom_id(split, helpers.dom_id(@event)),
                                                  partial: "events/course_setup_split",
                                                  locals: { event: @event, split: split, aid_station: nil })
      end
    end
  end

  private

  def aid_station_params
    params.require(:aid_station).permit(:split_id)
  end

  def authorize_organization
    organization = @event.organization
    authorize organization, policy_class: ::AidStationPolicy
  end

  def set_event
    @event = Event.find(params[:event_id])
  end
end
