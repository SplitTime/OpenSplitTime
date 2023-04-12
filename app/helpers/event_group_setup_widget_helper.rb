# frozen_string_literal: true

module EventGroupSetupWidgetHelper
  def link_to_setup_widget_course(presenter, event)
    if event.persisted?
      type = presenter.controller_name == "events" && presenter.action_name == "setup_course" && presenter.event == event ? :solid : :regular
      path = setup_course_event_group_event_path(event.event_group, event)
      tooltip = event.course.name
    else
      type = :regular
      path = nil
      tooltip = "You'll create or associate a Course when you set up your new Event"
    end

    if event.course.present?
      icon = fa_icon("check-circle", type: type, size: "2x", data: { controller: "tooltip", bs_original_title: tooltip })
      link_to icon, path
    else
      fa_icon "question-circle",
              type: type,
              size: "2x",
              class: "text-black",
              style: "--bs-text-opacity: .3;",
              data: { controller: "tooltip", bs_original_title: tooltip }
    end
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
    if event.persisted?
      type = presenter.controller_name == "events" && presenter.action_name == "edit" && presenter.event == event ? :solid : :regular
      path = edit_event_group_event_path(event.event_group, event)
      tooltip = event.guaranteed_short_name
    else
      type = presenter.controller_name == "events" && presenter.action_name == "new" ? :solid : :regular
      path = new_event_group_event_path(presenter.event_group)
      tooltip = "New Event"
    end

    icon = fa_icon("check-circle", type: type, size: "2x", data: { controller: "tooltip", bs_original_title: tooltip })
    link_to icon, path
  end

end
