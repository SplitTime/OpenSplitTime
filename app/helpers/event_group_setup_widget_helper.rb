module EventGroupSetupWidgetHelper
  def link_to_setup_widget_course(presenter, event)
    type = presenter.controller_name == "events" && presenter.action_name == "setup_course" && presenter.event == event ? :solid : :regular
    path = setup_course_event_group_event_path(event.event_group, event)
    tooltip = event.course.name
    icon = fa_icon("map-marked-alt",
                   type: type,
                   size: "2x",
                   data: { controller: "tooltip", bs_original_title: tooltip })

    link_to icon, path
  end

  def link_to_setup_widget_entrants(presenter)
    if presenter.event_group.new_record? || presenter.no_persisted_events?
      type = :regular
      tooltip = "You'll be able to add Entrants after your Event Group and Events are created"
      icon_only = true
    elsif presenter.active_widget_card == :entrants
      type = :solid
      tooltip = "Manage your Entrants"
      icon_only = false
    else
      type = :regular
      tooltip = "Manage your Entrants"
      icon_only = false
    end

    icon = fa_icon("people-group",
                   type: type,
                   size: "2x",
                   class: icon_only ? "text-black" : "",
                   style: icon_only ? "opacity: 0.4;" : "",
                   data: { controller: "tooltip", bs_original_title: tooltip })

    if icon_only
      icon
    else
      path = entrants_event_group_path(presenter.event_group)
      link_to icon, path
    end
  end

  def link_to_setup_widget_event_group(presenter)
    type = presenter.controller_name == "event_groups" && presenter.action_name.in?(%w(setup new)) ? :solid : :regular
    path = presenter.event_group.new_record? ? new_organization_event_group_path(presenter.organization) : setup_event_group_path(presenter.event_group)
    tooltip = "Event Group Overview"
    icon_name = "calendars"
    icon = fa_icon(icon_name,
                   type: type,
                   size: "2x",
                   data: { controller: "tooltip", bs_original_title: tooltip })

    link_to icon, path
  end

  def link_to_setup_widget_event(presenter, event)
    type = presenter.controller_name == "events" && presenter.action_name == "edit" && presenter.event == event ? :solid : :regular
    path = edit_event_group_event_path(event.event_group, event)
    tooltip = event.guaranteed_short_name
    icon = fa_icon("calendar-check",
                   type: type,
                   size: "2x",
                   data: { controller: "tooltip", bs_original_title: tooltip })

    link_to icon, path
  end

  def link_to_setup_widget_new_event(presenter)
    if presenter.controller_name == "events" && presenter.action_name == "new"
      type = :solid
      tooltip = ""
      icon_only = false
    elsif presenter.event_group.new_record?
      type = :regular
      tooltip = "You'll be able to add an Event after your Event Group is created"
      icon_only = true
    else
      type = :regular
      tooltip = "Add an Event"
      icon_only = false
    end

    icon = fa_icon("calendar-circle-plus",
                   type: type,
                   size: "2x",
                   class: icon_only ? "text-black" : "",
                   style: icon_only ? "opacity: 0.4;" : "",
                   data: { controller: "tooltip", bs_original_title: tooltip })

    if icon_only
      icon
    else
      path = new_event_group_event_path(presenter.event_group)
      link_to icon, path
    end
  end

  def link_to_setup_widget_partners(presenter)
    if presenter.event_group.new_record?
      type = :regular
      tooltip = "You'll be able to add Partners after your Event Group is created"
      icon_only = true
    elsif presenter.active_widget_card == :partners
      type = :solid
      tooltip = "Manage your Partners"
      icon_only = false
    else
      type = :regular
      tooltip = "Manage your Partners"
      icon_only = false
    end

    icon = fa_icon("handshake",
                   type: type,
                   size: "2x",
                   class: icon_only ? "text-black" : "",
                   style: icon_only ? "opacity: 0.4;" : "",
                   data: { controller: "tooltip", bs_original_title: tooltip })

    if icon_only
      icon
    else
      path = organization_event_group_partners_path(presenter.organization, presenter.event_group)
      link_to icon, path
    end
  end

  def link_to_setup_widget_summary(presenter)
    if presenter.controller_name == "event_groups" && presenter.action_name == "setup_summary"
      type = :solid
      tooltip = ""
      icon_only = false
    elsif presenter.event_group.new_record? || presenter.no_persisted_events?
      type = :regular
      tooltip = "You can view a summary here after your Event Group and Events are created"
      icon_only = true
    else
      type = :regular
      tooltip = "Change public/private status, enable and disable live entry, and see a summary of your Event Group"
      icon_only = false
    end

    icon = fa_icon("clipboard-list-check",
                   type: type,
                   size: "2x",
                   class: icon_only ? "text-black" : "",
                   style: icon_only ? "opacity: 0.4;" : "",
                   data: { controller: "tooltip", bs_original_title: tooltip })

    if icon_only
      icon
    else
      path = setup_summary_event_group_path(presenter.event_group)
      link_to icon, path
    end
  end
end
