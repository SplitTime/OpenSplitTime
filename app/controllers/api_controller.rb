class ApiController < ::ApplicationController
  include Rails::Pagination
  skip_forgery_protection
  before_action :authenticate_user!
  after_action :verify_authorized
  rescue_from ActiveRecord::RecordNotFound, with: :record_not_found_json

  private

  def permitted_params
    @permitted_params ||= prepared_params[:data]
  end

  def user_not_authorized
    render json: {errors: ["not authorized"]}, status: :unauthorized
  end

  def live_entry_unavailable(resource)
    {reportText: "Live entry for #{resource.name} is currently unavailable. " +
      "Please enable live entry access through the admin/settings page."}
  end
end
