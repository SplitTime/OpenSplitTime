# frozen_string_literal: true

class ExportJobsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_export_job, only: [:show, :destroy]
  after_action :set_exports_viewed_at

  # GET /export_jobs
  def index
    render locals: { export_jobs: current_user.export_jobs.most_recent_first.with_attached_file }
  end

  # GET /export_jobs/:id
  def show
  end

  # DELETE /export_jobs/:id
  def destroy
    unless @export_job.destroy
      flash[:danger] = "Unable to delete export job: #{@export_job.errors.full_messages.join(', ')}"
    end

    redirect_to export_jobs_path
  end

  private

  def set_export_job
    @export_job = current_user.export_jobs.find(params[:id])
  end

  def set_exports_viewed_at
    current_user.update(exports_viewed_at: ::Time.current)
  end
end
