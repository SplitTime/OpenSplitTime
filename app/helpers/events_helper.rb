module EventsHelper

  def link_to_edit_event(view_object)
    link_to 'Edit event', edit_event_path(view_object.event), class: 'btn btn-sm btn-primary'
  end

  def link_to_delete_event(view_object)
    link_to 'Delete event', event_path(view_object.event, referrer_path: events_path),
            method: :delete,
            data: {confirm: 'NOTE: This will delete the event and all associated efforts and split times. This action cannot be undone. Are you sure you want to go ahead?'},
            class: 'btn btn-sm btn-danger'
  end

  def link_to_beacon_button(view_object)
    if view_object.available_live && view_object.beacon_url
      link_to view_object.beacon_button_text, 
              url_with_protocol(view_object.beacon_url), 
              class: 'btn btn-sm btn-default', 
              target: '_blank'
    end
  end

  def link_to_enter_live_entry(view_object, current_user)
    if current_user && current_user.authorized_for_live?(view_object.event) && view_object.available_live
      link_to 'Live Data Entry', live_entry_live_event_path(view_object.event), method: :get, class: 'btn btn-sm btn-warning'
    end
  end

  def link_to_toggle_live_entry(view_object)
    if view_object.available_live
      link_to 'Disable live',
              live_disable_event_path(view_object.event),
              data: {confirm: "NOTE: This will suspend all live entry actions for #{view_object.name}, including any that may be in process. Are you sure you want to proceed?"},
              method: :put,
              class: 'btn btn-sm btn-warning'
    else
      link_to 'Enable live',
              live_enable_event_path(view_object.event),
              method: :put,
              class: 'btn btn-sm btn-warning'
    end
  end

  def link_to_stewards(view_object)
    link_to 'Stewards', stewards_race_path(view_object.race), class: 'btn btn-sm btn-warning' if view_object.race
  end

  def link_to_ultrasignup_export(view_object)
    link_to 'Export to ultrasignup', export_to_ultrasignup_event_path(view_object.event, format: :csv),
            class: 'btn btn-sm btn-success'
  end

  def link_to_set_dropped_splits(view_object)
    link_to 'Establish drops', set_dropped_split_ids_event_path(view_object.event),
            method: :put,
            data: {confirm: 'NOTE: For every effort that is unfinished, this will flag the effort as having dropped at the last aid station for which times are available. Are you sure you want to proceed?'},
            class: 'btn btn-sm btn-success'
  end

  def link_to_set_data_status(view_object)
    link_to 'Set data status', set_data_status_event_path(view_object.event),
            method: :put,
            class: 'btn btn-sm btn-success'
  end

  def link_to_start_all_efforts(view_object)
    link_to 'Start all efforts', start_all_efforts_event_path(view_object.event),
            method: :put,
            data: {confirm: "NOTE: This will create a starting split time for all efforts associated with #{view_object.name}. Are you sure you want to proceed?"},
            class: 'btn btn-sm btn-success'
  end

  def suggested_match_id_hash(efforts)
    efforts.select(&:suggested_match).map { |effort| [effort.id, effort.suggested_match.id] }.to_h
  end

  def suggested_match_count(efforts)
    suggested_match_id_hash(efforts).count
  end

  def data_status(status_int)
    Effort.data_statuses.key(status_int)
  end

  def explore_button_disabled?(klass)
    klass == EventEffortsDisplay || klass == EventPreviewDisplay
  end

  def spread_button_disabled?(klass)
    klass == EventSpreadDisplay
  end

  def stage_button_disabled?(klass)
    klass == EventStageDisplay
  end

end
