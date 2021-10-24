class ImportJobsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_import_job, :only => [:destroy]
  after_action :verify_authorized, except: :index

  # GET /users/:user_id/import_jobs
  def index
    @user = current_user
  end

  # POST /users/:user_id/import_jobs
  def create
    @import_job = ::ImportJob.new(:user_id => current_user.id, :status => :waiting)
    file = params.dig(:import_job, :file)
    @import_job.file.attach(file)

    if file.present? && @import_job.save
      ::ImportAsyncJob.perform_later(@import_job)
      flash[:success] = "Import in progress."
    else
      flash[:danger] = "Unable to create import job: #{@import_job.errors.full_messages.join(', ')}"
    end

    redirect_to request.referrer || user_import_jobs_path
  end

  # DELETE /users/:user_id/import_jobs/:id
  def destroy
    unless @import_job.destroy
      flash[:danger] = "Unable to delete import job: #{@import_job.errors.full_messages.join(', ')}"
    end

    redirect_to user_import_jobs_path
  end

  private

  def set_import_job
    @import_job = ImportJob.find(params[:id])
  end
end
