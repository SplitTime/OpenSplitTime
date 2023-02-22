class ImportJobsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_import_job, only: [:show, :destroy]
  after_action :verify_authorized, only: [:new, :create]

  # GET /import_jobs
  def index
    render locals: { import_jobs: current_user.import_jobs.most_recent_first.with_attached_files }
  end

  # GET /import_jobs/:id
  def show
  end

  # GET /import_jobs/new
  def new
    @import_job = current_user.import_jobs.new(permitted_params)
    @parent_resource = @import_job.parent # If not found, return 404 before authorization

    authorize @import_job
  end

  # POST /import_jobs
  def create
    @import_job = current_user.import_jobs.new(permitted_params)
    @import_job.status = :waiting
    @parent_resource = @import_job.parent # If not found, return 404 before authorization

    authorize @import_job

    begin
      if @import_job.save
        ::ImportAsyncJob.perform_later(@import_job.id)
        flash[:success] = "Import in progress."
        redirect_to import_jobs_path
      else
        flash[:danger] = "Unable to create import job: #{@import_job.errors.full_messages.join(', ')}"
        render "new", status: :unprocessable_entity
      end
    rescue Aws::Errors::NoSuchEndpointError => e
      flash[:danger] = "Unable to create import job: #{e}"
      @import_job.failed!
      render "new", status: :unprocessable_entity
    end
  end

  # DELETE /import_jobs/:id
  def destroy
    unless @import_job.destroy
      flash[:danger] = "Unable to delete import job: #{@import_job.errors.full_messages.join(', ')}"
    end

    redirect_to import_jobs_path(user_id: @user.id)
  end

  private

  def set_import_job
    @import_job = current_user.import_jobs.find(params[:id])
  end
end
