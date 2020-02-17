# frozen_string_literal: true

class StageEventGroup::YourEventPresenter < StageEventGroup::BasePresenter
  def post_initialize
    assign_event_group_attributes
  end

  def cancel_link
    case
    when event_group.persisted?
      Rails.application.routes.url_helpers.event_group_path(event_group, force_settings: true)
    when organization.persisted?
      Rails.application.routes.url_helpers.organization_path(organization)
    else
      Rails.application.routes.url_helpers.event_groups_path
    end
  end

  def current_step
    'your_event'
  end

  private

  def assign_event_group_attributes
    event_group.assign_attributes(organization_id: params[:organization_id]) if params[:organization_id].present?
  end
end
