# frozen_string_literal: true

module EventsHelper
  def results_template_selector(resource)
    public_organization = Organization.new(name: "Public Templates", results_templates: ResultsTemplate.standard)
    private_organization = resource.organization.results_templates.present? ? resource.organization : nil
    organizations = [public_organization, private_organization].compact
    resource_type = resource.class.name.underscore.to_sym

    grouped_collection_select(resource_type, :results_template_id, organizations, :results_templates, :name, :id, :name,
                              {prompt: false},
                              {class: "form-control dropdown-select-field",
                               data: {"results-template-target" => "dropdown", action: "results-template#replaceCategories"}})
  end

  def link_to_beacon_button(view_object)
    if view_object.beacon_url
      link_to event_beacon_button_text(view_object.beacon_url),
              url_with_protocol(view_object.beacon_url),
              class: "btn btn-outline-secondary",
              target: "_blank"
    end
  end

  def link_to_download_spread_csv(view_object, current_user)
    if current_user&.authorized_to_edit?(view_object.event) && view_object.event_finished?
      link_to "Export spreadsheet",
              spread_event_path(view_object.event, format: :csv, display_style: view_object.display_style, sort: view_object.sort_hash),
              class: "btn btn-md btn-success"
    end
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
    view_object.respond_to?(:display_style) && (view_object.display_style == "splits") ? "splits" : "entrants"
  end
end
