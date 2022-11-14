class ExportJobsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_export_job, only: [:destroy]
  after_action :verify_authorized

  # GET /export_jobs
  def index
    authorize ::ExportJob
  end

  # GET /export_jobs/:id
  def show
    authorize @export_job
  end

  # POST /export_jobs
  def create
    @export_job = current_user.export_jobs.new(permitted_params)
    @export_job.status = :waiting

    authorize @export_job

    begin
      if @export_job.save
        ::ExportAsyncJob.perform_later(@export_job.id)
        flash[:success] = "Export in progress."
        redirect_to export_jobs_path
      else
        flash[:danger] = "Unable to create export job: #{@export_job.errors.full_messages.join(', ')}"
        render "new", status: :unprocessable_entity
      end
    rescue Aws::Errors::NoSuchEndpointError => e
      flash[:danger] = "Unable to create export job: #{e}"
      @export_job.failed!
      render "new", status: :unprocessable_entity
    end
  end

  # DELETE /export_jobs/:id
  def destroy
    authorize @export_job

    unless @export_job.destroy
      flash[:danger] = "Unable to delete export job: #{@export_job.errors.full_messages.join(', ')}"
    end

    redirect_to export_jobs_path
  end

  private

  def set_export_job
    @export_job = current_user.export_jobs.find(params[:id])
  end
end
