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
    @export_job.destroy

    respond_to do |format|
      format.html { redirect_to export_jobs_path, notice: "Export job was deleted." }
      format.turbo_stream
    end
  end

  private

  def set_export_job
    @export_job = current_user.export_jobs.find(params[:id])
  end

  def set_exports_viewed_at
    current_user.update(exports_viewed_at: ::Time.current)
  end
end
