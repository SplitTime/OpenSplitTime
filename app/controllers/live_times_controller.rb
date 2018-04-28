class LiveTimesController < ApplicationController
  before_action :set_live_time

  def update
    authorize @live_time

    unless @live_time.update(permitted_params)
      flash[:danger] = "Live time could not be updated.\n#{@live_time.errors.full_messages.join("\n")}"
    end
    redirect_to_event
  end

  def destroy
    authorize @live_time

    @live_time.destroy
    redirect_to_event
  end

  private

  def set_live_time
    @live_time = LiveTime.find(params[:id])
  end

  def redirect_to_event
    redirect_to params[:referrer_path].permit(:action, :controller, :id, :display_style) ||
                    stage_event_path(@live_time.event_id, display_style: :times)
  end
end
