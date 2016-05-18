class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception
  before_action :set_current_user

  def conform_physical_data(base_split)
    conform_split_locations(base_split)
    conform_vert(base_split)
  end


  def conform_split_locations(base_split)
    if base_split.location.nil?
      split = base_split.waypoint_group.where.not(location_id: nil).first
      base_split.update(location_id: split.location_id) if split
    else
      location_id = base_split.location.id
      splits = base_split.waypoint_group.where.not(id: base_split.id)
      splits.update_all(location_id: location_id)
    end
  end

  def conform_vert(base_split)
    if base_split.vert_gain_from_start.nil?
      split = base_split.waypoint_group.where.not(vert_gain_from_start: nil).first
      base_split.update(vert_gain_from_start: split.vert_gain_from_start) if split
    else
      vert_gain = base_split.vert_gain_from_start
      splits = base_split.waypoint_group.where.not(id: base_split.id)
      splits.update_all(vert_gain_from_start: vert_gain)
    end
    if base_split.vert_loss_from_start.nil?
      split = base_split.waypoint_group.where.not(vert_loss_from_start: nil).first
      base_split.update(vert_loss_from_start: split.vert_loss_from_start) if split
    else
      vert_loss = base_split.vert_loss_from_start
      splits = base_split.waypoint_group.where.not(id: base_split.id)
      splits.update_all(vert_loss_from_start: vert_loss)
    end
  end

  def set_sub_order(base_split)
    group = base_split.waypoint_group
    return if group.count == 1
    if group.count == 2
      first = group[0]
      second = group[1]
      if first.name.downcase.include?("out") && second.name.downcase.include?("in")
        first.update(sub_order: 1)
        second.update(sub_order: 0)
        return
      elsif first.name.downcase.include?("in") && second.name.downcase.include?("out")
        first.update(sub_order: 0)
        second.update(sub_order: 1)
        return
      end
    end
    existing = group.reject { |x| x.id == base_split.id }.map(&:sub_order)
    new = existing.include?(0) ? existing.max + 1 : 0
    base_split.update(sub_order: new)
  end

  if Rails.env.development? | Rails.env.test?
    # https://github.com/RailsApps/rails-devise-pundit/issues/10
    include Pundit
    rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized
  end

  private

  def user_not_authorized
    flash[:alert] = "Access denied."
    redirect_to (request.referrer || root_path)
  end

  def set_current_user
    User.current = current_user
  end


end
