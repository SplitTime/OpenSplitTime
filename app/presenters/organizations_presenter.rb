# frozen_string_literal: true

class OrganizationsPresenter < BasePresenter
  attr_reader :organizations

  def initialize(organizations, params, current_user)
    @organizations = organizations
    @params = params
    @current_user = current_user
  end

  def events_count(organization)
    events(organization).size
  end

  private

  attr_reader :params, :current_user

  def events(organization)
    grouped_event_groups[organization.id]&.flat_map(&:events) || []
  end

  def grouped_event_groups
    event_groups.group_by(&:organization_id)
  end

  def event_groups
    @event_groups ||= EventGroupPolicy::Scope.new(current_user, EventGroup).viewable.includes(:events)
  end
end
