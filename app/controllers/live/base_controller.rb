class Live::BaseController < ApplicationController

  before_action :authenticate_user!
  after_action :verify_authorized

  private

  def verify_available_live(resource)
    unless resource.available_live
      flash[:danger] = "#{resource.name} is not available for live entry. Please enable live entry access through the event group settings page."
      redirect_to resource
    end
  end
end
