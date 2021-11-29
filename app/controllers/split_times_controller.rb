# frozen_string_literal: true

class SplitTimesController < ApplicationController
  before_action :authenticate_user!
  after_action :verify_authorized

  def update
    @split_time = SplitTime.find(params[:id])
    authorize @split_time
    effort = Effort.find(@split_time.effort_id)

    if @split_time.update(permitted_params)
      Interactors::UpdateEffortsStatus.perform!(effort)
      redirect_to audit_effort_path(@split_time.effort_id)
    else
      flash[:danger] = "Raw time could not be matched:\n#{@split_time.errors.full_messages.join("\n")}"
      @presenter = EffortAuditView.new(effort)
      render 'efforts/audit'
    end
  end
end
