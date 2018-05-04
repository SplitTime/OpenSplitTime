class LiveTimesController < ApplicationController
  include BackgroundNotifiable

  before_action :set_live_time

  def update
    authorize @live_time

    if @live_time.update(permitted_params)
      report_live_times_available(@live_time.event.event_group)
    else
      flash[:danger] = "Live time could not be updated.\n#{@live_time.errors.full_messages.join("\n")}"
    end
    redirect_to request.referrer
  end

  def destroy
    authorize @live_time

    @live_time.destroy
    redirect_to request.referrer
  end

  private

  def set_live_time
    @live_time = LiveTime.find(params[:id])
  end
end
