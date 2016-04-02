class EventSplitsController < ApplicationController
  before_action :authenticate_user!
  after_action :verify_authorized


  private

  def event_split_params
    params.require(:event_split).permit(:event_id, :split_id)
  end


end