# frozen_string_literal: true

module EventGroupSetupWidgetHelper
  def link_to_setup_widget_course(presenter, event)
    type = presenter.controller_name == "events" && presenter.action_name == "setup_course" && presenter.event == event ? :solid : :regular
    path = setup_course_event_group_event_path(event.event_group, event)
    tooltip = event.course.name

    icon = fa_icon("check-circle", type: type, size: "2x", data: { controller: "tooltip", bs_original_title: tooltip })
    link_to icon, path
  end

  def link_to_setup_widget_entrants(presenter)
    type = presenter.controller_name == "event_groups" && presenter.action_name == "setup" && presenter.display_style == "entrants" ? :solid : :regular

    link_to fa_icon("check-circle",
                    type: type,
                    size: "2x",
                    data: { controller: "tooltip", bs_original_title: "Entrants have not yet been imported" }),
            setup_event_group_path(presenter.event_group, display_style: :entrants)
  end

  def link_to_setup_widget_event_group(presenter)
    type = presenter.controller_name == "event_groups" && presenter.action_name == "setup" && presenter.display_style != "entrants" ? :solid : :regular

    link_to fa_icon("check-circle", type: type, size: "2x"),
            setup_event_group_path(presenter.event_group)
  end

  def link_to_setup_widget_event(presenter, event)
    type = presenter.controller_name == "events" && presenter.action_name == "edit" && presenter.event == event ? :solid : :regular
    path = edit_event_group_event_path(event.event_group, event)
    tooltip = event.guaranteed_short_name

    icon = fa_icon("check-circle", type: type, size: "2x", data: { controller: "tooltip", bs_original_title: tooltip })
    link_to icon, path
  end

  def link_to_setup_widget_new_event(presenter)
    if presenter.controller_name == "events" && presenter.action_name == "new"
      type = :solid
      tooltip = ""
    else
      type = :regular
      tooltip = "Add an Event"
    end

    path = new_event_group_event_path(presenter.event_group)

    icon = fa_icon("plus-square", type: type, size: "2x", data: { controller: "tooltip", bs_original_title: tooltip })
    link_to icon, path
  end

end
