class EventSplitsController < ApplicationController
  before_action :authenticate_user!
  after_action :verify_authorized

  def destroy
    @event_split = EventSplit.find(params[:id])
    authorize @event_split
    @event_split.destroy
    redirect_to splits_event_url(id: @event_split.event_id)
  end

  private

  def event_split_params
    params.require(:event_split).permit(:event_id, :split_id)
  end


end