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
    @splits = base_split.waypoint_group.where.not(id: base_split.id)
    @splits.each do |split|
      split.update_attributes(location_id: location_id)
    end
  end

  def set_sub_order(base_split)
    group = base_split.waypoint_group
    return if group.count == 1
    if group.count == 2
      first = group[0]
      second = group[1]
      if first.name.downcase.include?("out") && second.name.downcase.include?("in")
        first.update_attributes(sub_order: 1)
        second.update_attributes(sub_order: 0)
        return
      elsif first.name.downcase.include?("in") && second.name.downcase.include?("out")
        first.update_attributes(sub_order: 0)
        second.update_attributes(sub_order: 1)
        return
      end
    end
    existing = group.reject { |x| x.id == base_split.id }.map(&:sub_order)
    new = existing.include?(0) ? existing.max + 1 : 0
    base_split.update_attributes(sub_order: new)
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
