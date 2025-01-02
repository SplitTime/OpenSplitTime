class RawTimesController < ApplicationController
  include BackgroundNotifiable

  before_action :set_raw_time

  def update
    authorize @raw_time
    @effort = Effort.find(params[:effort_id]) if params[:effort_id].present?

    if @raw_time.update(permitted_params)
      report_raw_times_available(@raw_time.event_group)
      respond_to do |format|
        format.html { redirect_to request.referrer || root_path }
        format.turbo_stream do
          @audit_presenter = EffortAuditView.new(@effort) if @effort.present?
          @event_group = @raw_time.event_group
        end
      end
    else
      message = "Raw time could not be updated.\n#{@raw_time.errors.full_messages.join("\n")}"

      respond_to do |format|
        format.html do
          flash[:danger] = message
          redirect_to request.referrer || root_path
        end
        format.turbo_stream { flash.now[:danger] = message }
      end
    end
  end

  def destroy
    authorize @raw_time

    if @raw_time.destroy
      respond_to do |format|
        format.html { redirect_to request.referrer }
        format.turbo_stream { flash.now[:success] = "Raw time was deleted." }
      end
    else
      respond_to do |format|
        format.html { redirect_to request.referrer || root_path }

        format.turbo_stream do
          flash.now[:danger] = "Raw time could not be deleted."
          render turbo_stream: turbo_stream.replace("flash", partial: "layouts/flash")
        end
      end
    end
  end

  private

  def set_raw_time
    @raw_time = RawTime.find(params[:id])
  end
end
