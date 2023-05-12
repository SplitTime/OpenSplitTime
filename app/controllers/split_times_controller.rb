# frozen_string_literal: true

class SplitTimesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_split_time_and_effort
  before_action :authorize_split_time
  after_action :verify_authorized

  def update
    respond_to do |format|
      format.turbo_stream do
        if @split_time.update(permitted_params)
          Interactors::UpdateEffortsStatus.perform!(@effort)
          @show_presenter = EffortShowView.new(@effort)
          @audit_presenter = EffortAuditView.new(@effort)
        else
          flash.now[:danger] = @split_time.errors.full_messages.join("\n")
        end
      end
    end
  end

  def destroy
    respond_to do |format|
      format.turbo_stream do
        if @split_time.destroy
          Interactors::UpdateEffortsStatus.perform!(@effort)
          @show_presenter = EffortShowView.new(@effort)
          @audit_presenter = EffortAuditView.new(@effort)
        else
          flash.now[:danger] = @split_time.errors.full_messages.join("\n")
        end

        render :update
      end
    end
  end

  private

  def authorize_split_time
    authorize @split_time
  end

  def set_split_time_and_effort
    @split_time = SplitTime.find(params[:id])
    @effort = Effort.find(@split_time.effort_id)
  end
end
