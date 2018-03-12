# frozen_string_literal: true

class OrganizationPresenter < BasePresenter

  attr_reader :organization
  delegate :id, :name, :description, :stewards, :to_param, to: :organization

  def initialize(organization, params, current_user)
    @organization = organization
    @params = params
    @current_user = current_user
  end

  def event_groups
    scoped_event_groups = EventGroupPolicy::Scope.new(current_user, EventGroup).viewable.search(params[:search])
    EventGroup.where(id: scoped_event_groups.map(&:id), organization: organization)
        .includes(events: :efforts).includes(:organization)
        .sort_by { |event_group| -event_group.start_time.to_i }
  end

  def courses
    @courses ||= Course.includes(:splits, :events).used_for_organization(organization)
  end

  def display_style
    %w[courses stewards events].include?(params[:display_style]) ? params[:display_style] : default_display_style
  end

  def default_display_style
    'events'
  end

  def show_visibility_columns?
    current_user&.authorized_to_edit?(organization)
  end

  private

  attr_reader :params, :current_user
end
