# frozen_string_literal: true

module EventsHelper
  def results_template_selector(event)
    public_organization = Organization.new(name: 'Public Templates', results_templates: ResultsTemplate.standard)
    private_organization = event.organization
    organizations = [public_organization, private_organization]

    grouped_collection_select(:event, :results_template_id, organizations, :results_templates, :name, :id, :name,
                      {prompt: false},
                      {class: "form-control dropdown-select-field",
                       data: {target: 'event-form.dropdown', action: 'event-form#replaceCategories'}})
  end

  def link_to_beacon_button(view_object)
    if view_object.beacon_url
      link_to event_beacon_button_text(view_object.beacon_url),
              url_with_protocol(view_object.beacon_url),
              class: 'btn btn-outline-secondary',
              target: '_blank'
    end
  end

  def link_to_download_spread_csv(view_object, current_user)
    if current_user&.authorized_to_edit?(view_object.event) && view_object.event_finished?
      link_to 'Export spreadsheet',
              spread_event_path(view_object.event, format: :csv, display_style: view_object.display_style, sort: view_object.sort_hash),
              method: :get, class: 'btn btn-md btn-success'
    end
  end

  def link_to_toggle_live_entry(view_object)
    if view_object.available_live?
      button_text = 'Disable live'
      confirm_text = "NOTE: This will suspend all live entry actions for #{view_object.event_group_names}, " +
          'including any that may be in process, and will disable live follower notifications ' +
          'by email and SMS text when new times are added. Are you sure you want to proceed?'
    else
      button_text = 'Enable live'
      confirm_text = "NOTE: This will enable live entry actions for #{view_object.event_group_names}, " +
          'and will also trigger live follower notifications by email and SMS text when new times are added. ' +
          'Are you sure you want to proceed?'
    end

    link_to button_text,
            event_group_path(view_object.event_group, event_group: {available_live: !view_object.available_live?}),
            data: {confirm: confirm_text},
            method: :put,
            class: 'btn btn-md btn-warning'
  end

  def link_to_toggle_public_private(view_object)
    if view_object.concealed?
      button_text = 'Make public'
      confirm_text = "NOTE: This will make #{view_object.event_group_names} visible to the public, " +
          'including all related efforts and people. Are you sure you want to proceed?'
    else
      button_text = 'Make private'
      confirm_text = "NOTE: This will conceal #{view_object.event_group_names} from the public, " +
          'including all related efforts. Are you sure you want to proceed?'
    end

    link_to button_text,
            event_group_path(view_object.event_group, event_group: {concealed: !view_object.concealed?}),
            data: {confirm: confirm_text},
            method: :put,
            class: 'btn btn-md btn-warning'
  end

  def link_to_toggle_ost_remote(view_object)
    if view_object.auto_live_times?
      button_text = 'OST Remote Manual'
      confirm_text = "NOTE: Times imported from OST Remote into #{view_object.event_group_names} " +
          'will need to be manually updated in the Live Entry view. Are you sure you want to proceed?'
    else
      button_text = 'OST Remote Auto'
      confirm_text = "NOTE: Times imported from OST Remote into #{view_object.event_group_names} " +
          'will be automatically updated, with only duplicate and bad times requiring attention ' +
          'in the Live Entry view. Are you sure you want to proceed?'
    end

    link_to button_text,
            event_group_path(view_object.event_group, event_group: {auto_live_times: !view_object.auto_live_times?}),
            data: {confirm: confirm_text},
            method: :put,
            class: 'btn btn-md btn-warning'
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

  def event_staging_app_page(view_object)
    (view_object.respond_to?(:display_style)) && (view_object.display_style == 'splits') ? 'splits' : 'entrants'
  end
end
