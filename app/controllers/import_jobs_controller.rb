class ImportJobsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_user
  before_action :set_import_job, only: [:show, :destroy]
  after_action :verify_authorized

  # GET /import_jobs
  def index
    authorize @user
  end

  # GET /import_jobs/:id
  def show
    authorize @user
  end

  # GET /import_jobs/new
  def new
    authorize @user

    @import_job = ::ImportJob.new(permitted_params)
    @import_job.user = @user
  end

  # POST /import_jobs
  def create
    authorize @user

    @import_job = ::ImportJob.new(permitted_params)
    @import_job.status = :waiting
    @import_job.user = current_user

    begin
      if @import_job.save
        ::ImportAsyncJob.perform_later(@import_job.id)
        flash[:success] = "Import in progress."
        redirect_to import_jobs_path
      else
        flash[:danger] = "Unable to create import job: #{@import_job.errors.full_messages.join(', ')}"
        render "new"
      end
    rescue Aws::Errors::NoSuchEndpointError => e
      flash[:danger] = "Unable to create import job: #{e}"
      @import_job.failed!
      render "new"
    end
  end

  # DELETE /import_jobs/:id
  def destroy
    authorize @user

    unless @import_job.destroy
      flash[:danger] = "Unable to delete import job: #{@import_job.errors.full_messages.join(', ')}"
    end

    redirect_to import_jobs_path(user_id: @user.id)
  end

  private

  def set_import_job
    @import_job = @user.import_jobs.find(params[:id])
  end

  def set_user
    @user = if current_user.admin?
              User.find_by(id: params[:user_id]) || current_user
            else
              current_user
            end
  end
end
