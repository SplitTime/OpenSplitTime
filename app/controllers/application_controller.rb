class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception
  before_action :set_current_author

  def set_current_author
    Concern::Audit::Author.current = current_user.try(:id)
  end

  def conform_split_locations_to(base_split)
    location_id = base_split.location.id
    @splits = Split.having_same_distance_as(base_split)
    @splits.each do |split|
      split.update_attributes(location_id: location_id)
    end
  end

  if Rails.env.development?
    # https://github.com/RailsApps/rails-devise-pundit/issues/10
    include Pundit
    # https://github.com/elabs/pundit#ensuring-policies-are-used
    # after_action :verify_authorized, except: :index, unless: :devise_controller?  # TODO: implement these verifications
    # after_action :verify_policy_scoped, only: :index, unless: :devise_controller?

    rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized

    private

    def user_not_authorized
      flash[:alert] = "Access denied."
      redirect_to (request.referrer || root_path)
    end

  end
end
