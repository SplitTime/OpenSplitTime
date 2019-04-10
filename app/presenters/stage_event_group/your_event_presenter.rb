# frozen_string_literal: true

class StageEventGroup::YourEventPresenter < StageEventGroup::BasePresenter
  def post_initialize; end

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
end
