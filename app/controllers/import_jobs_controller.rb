# frozen_string_literal: true

require "etl"

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

  def csv_templates
    skip_authorization

    respond_to do |format|
      format.csv do
        parent = params[:parent_type].constantize.find(params[:parent_id])
        import_job_format = params[:import_job_format].to_sym
        csv_template_headers = ::Etl::CsvTemplates.headers(import_job_format, parent)
        csv_template = csv_template_headers.join(",") + "\n"
        filename_components = [import_job_format, parent.class.name.underscore, parent.id, "template.csv"]
        filename = filename_components.join("_")

        send_data csv_template, type: "text/csv", filename: filename
      end
    end
  end

  private

  def set_import_job
    @import_job = current_user.import_jobs.find(params[:id])
  end
end
