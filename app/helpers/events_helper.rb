module EventsHelper

  def link_to_edit_event(view_object)
    link_to 'Edit event', edit_event_path(view_object.event), class: 'btn btn-sm btn-primary'
  end

  def link_to_delete_event(view_object)
    link_to 'Delete event', event_path(view_object.event, referrer_path: events_path),
            method: :delete,
            data: {confirm: 'NOTE: This will delete the event and all associated efforts and split times. ' +
                'This action cannot be undone. Are you sure you want to go ahead?'},
            class: 'btn btn-sm btn-danger'
  end

  def link_to_beacon_button(view_object)
    if view_object.beacon_url
      link_to event_beacon_button_text(view_object.beacon_url),
              url_with_protocol(view_object.beacon_url),
              class: 'btn btn-sm btn-default',
              target: '_blank'
    end
  end

  def link_to_enter_live_entry(view_object, current_user)
    if current_user && current_user.authorized_to_edit?(view_object.event) && view_object.available_live
      link_to 'Live Entry', live_entry_live_event_path(view_object), method: :get, class: 'btn btn-sm btn-warning'
    end
  end

  def link_to_classic_admin(view_object, current_user)
    if current_user && current_user.authorized_to_edit?(view_object.event)
      link_to 'Admin', stage_event_path(view_object),
              disabled: stage_button_disabled?(view_object.class),
              class: 'btn btn-sm btn-primary'
    end
  end

  def link_to_event_staging(view_object, current_user)
    if current_user && current_user.authorized_to_edit?(view_object.event)
      link_to 'Event Staging', "#{event_staging_app_path(view_object)}#/#{event_staging_app_page(view_object)}",
              class: 'btn btn-sm btn-primary'
    end
  end

  def link_to_download_spread_csv(view_object, current_user)
    if current_user && current_user.authorized_to_edit?(view_object.event) && view_object.event_finished?
      link_to 'Export spreadsheet',
              spread_event_path(view_object.event, format: :csv, display_style: view_object.display_style, sort: view_object.sort_hash),
              method: :get, class: 'btn btn-sm btn-success'
    end
  end

  def link_to_toggle_live_entry(view_object)
    if view_object.available_live
      link_to 'Disable live',
              event_path(view_object.event, event: {available_live: false}),
              data: {confirm: "NOTE: This will suspend all live entry actions for #{view_object.name}, " +
                  'including any that may be in process, and will disable live follower notifications ' +
                  'by email and SMS text when new times are added. Are you sure you want to proceed?'},
              method: :put,
              class: 'btn btn-sm btn-warning'
    else
      link_to 'Enable live',
              event_path(view_object.event, event: {available_live: true}),
              data: {confirm: "NOTE: This will enable live entry actions for #{view_object.name}, " +
                  'and will also trigger live follower notifications by email and SMS text when new times are added. ' +
                  'Are you sure you want to proceed?'},
              method: :put,
              class: 'btn btn-sm btn-warning'
    end
  end

  def link_to_stewards(view_object)
    link_to 'Stewards', stewards_organization_path(view_object.organization), class: 'btn btn-sm btn-warning' if view_object.organization
  end

  def link_to_ultrasignup_export(view_object)
    link_to 'Export to ultrasignup', export_to_ultrasignup_event_path(view_object.event, format: :csv),
            class: 'btn btn-sm btn-success'
  end

  def link_to_set_dropped_attributes(view_object)
    link_to 'Establish drops', set_dropped_attributes_event_path(view_object.event),
            method: :put,
            data: {confirm: 'NOTE: For every effort that is unfinished, this will flag the effort as having stopped ' +
                'at the last aid station for which times are available. Are you sure you want to proceed?'},
            class: 'btn btn-sm btn-success'
  end

  def link_to_set_data_status(view_object)
    link_to 'Set data status', set_data_status_event_path(view_object.event),
            method: :put,
            class: 'btn btn-sm btn-success'
  end

  def link_to_podium(view_object)
    link_to 'Podium', podium_event_path(view_object.event),
            class: 'btn btn-sm btn-success'
  end

  def link_to_start_ready_efforts(view_object)
    if view_object.ready_efforts.present?
      link_to "Start #{pluralize(view_object.ready_efforts_count, 'effort')}",
              start_ready_efforts_event_path(view_object.event),
              method: :put,
              data: {confirm: 'NOTE: This will create a starting split time for the ' +
                  "#{pluralize(view_object.ready_efforts_count, 'unstarted effort')} " +
                  'scheduled to start before the current time. Are you sure you want to proceed?'},
              class: 'start-ready-efforts btn btn-sm btn-success'
    else
      link_to 'Nothing to start', '#', disabled: true,
              data: {confirm: 'No efforts are ready to start. Reload the page to check again.'},
              class: 'start-ready-efforts btn btn-sm btn-success'
    end
  end

  def link_to_stage_efforts_field(view_object, field_name, column_heading)
    link_to column_heading, stage_event_path(view_object,
                                             display_style: view_object.display_style,
                                             started: view_object.started_filter?,
                                             checked_in: view_object.checked_in_filter?,
                                             sort: (view_object.existing_sort == field_name.to_s) ? "-#{field_name}" : field_name.to_s)
  end

  def link_to_spread_gender(view_object, gender)
    link_to gender.titlecase, spread_event_path(view_object,
                                                'filter[gender]' => gender,
                                                'sort' => view_object.existing_sort,
                                                'display_style' => view_object.display_style),
            disabled: view_object.gender_text == gender,
            class: 'btn btn-sm btn-primary'
  end

  def link_to_spread_display_style(view_object, display_style, title)
    link_to title, spread_event_path(view_object.event,
                                         :display_style => display_style,
                                         :sort => view_object.sort_string,
                                         'filter[gender]' => view_object.gender_text),
            disabled: view_object.display_style == display_style,
            class: 'btn btn-sm btn-primary'
  end

  def link_to_stage_display_style(view_object, display_style, title)
    link_to title,
            stage_event_path(view_object, display_style: display_style),
            disabled: view_object.display_style == display_style,
            class: 'btn btn-sm btn-primary'
  end

  def suggested_match_id_hash(efforts)
    efforts.select(&:suggested_match).map { |effort| [effort.id, effort.suggested_match.id] }.to_h
  end

  def suggested_match_count(efforts)
    suggested_match_id_hash(efforts).size
  end

  def data_status(status_int)
    Effort.data_statuses.key(status_int)
  end

  def explore_button_disabled?(klass)
    klass == EventEffortsDisplay
  end

  def spread_button_disabled?(klass)
    klass == EventSpreadDisplay
  end

  def stage_button_disabled?(klass)
    klass == EventStageDisplay
  end

  def event_staging_app_page(view_object)
    (view_object.respond_to?(:view_text)) && (view_object.view_text == 'splits') ? 'splits' : 'entrants'
  end
end
