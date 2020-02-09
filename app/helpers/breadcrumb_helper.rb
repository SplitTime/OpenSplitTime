# frozen_string_literal: true

module BreadcrumbHelper
  def effort_view_breadcrumbs(presenter, title)
    content_tag(:ul, class: 'breadcrumb breadcrumb-ost') do
      concat content_tag(:li, link_to('Organizations', organizations_path), class: 'breadcrumb-item')
      concat content_tag(:li, link_to(presenter.event_group.organization.name, organization_path(presenter.event_group.organization)), class: 'breadcrumb-item')
      if presenter.event_group.multiple_events?
        concat content_tag(:li, link_to(presenter.event_group.name, event_group_path(presenter.event_group)), class: 'breadcrumb-item')
      end
      concat content_tag(:li, link_to(presenter.event.guaranteed_short_name, event_path(presenter.event)), class: 'breadcrumb-item')
      if title.present?
        concat content_tag(:li, link_to(presenter.full_name, effort_path(presenter.effort)), class: 'breadcrumb-item')
        concat content_tag(:li, title, class: 'breadcrumb-item active')
      else
        concat content_tag(:li, presenter.full_name, class: 'breadcrumb-item')
      end
    end
  end
end
