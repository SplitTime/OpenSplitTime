module DropdownHelper
  def build_dropdown_menu(title, items, options = {})
    main_active = items.any? { |item| item[:active] } ? "active" : nil

    container_tag = options[:button] ? :div : :li
    container_class = options[:button] ? "btn-group" : main_active
    content_tag container_tag, class: [container_class, options[:class]].join(" ") do
      toggle_tag = options[:button] ? :button : :a
      button_type = options[:button_type] || "outline-secondary"
      toggle_class = (options[:button] ? "btn btn-#{button_type}" : "") + " dropdown-toggle"
      concat content_tag(toggle_tag, class: toggle_class, data: { bs_toggle: "dropdown" }) {
        active_name = items.find { |item| item[:active] }&.dig(:name)
        safe_concat [title, active_name].compact.join(" / ")
        safe_concat "&nbsp;"
        concat content_tag(:span, "", class: "caret")
      }

      concat content_tag(:div, class: "dropdown-menu") {
        items.reject { |item| item[:visible] == false }.each do |item|
          if item[:role] == :separator
            concat content_tag(:div, "", class: "dropdown-divider")
          else
            active = item[:active] ? "active" : nil
            disabled = item[:disabled] ? "disabled" : nil
            html_class = ["dropdown-item", active, disabled, item[:class]].compact.join(" ")
            concat link_to item[:name], item[:link], { class: html_class }.merge(item.slice(:method, :data))
          end
        end
      }
    end
  end

  def connection_services_dropdown_menu(view_object)
    dropdown_items = view_object.available_connection_services.map do |service|
      { name: service.name,
        link: event_group_connect_service_path(view_object.event_group, service.identifier),
        disabled: service.identifier.in?(view_object.existing_service_identifiers) }
    end

    build_dropdown_menu(
      fa_icon("plug-circle-plus", type: :regular, class: "text-success", text: "Select a service to connect"),
      dropdown_items,
      button: true,
      button_type: "outline-success"
    )
  end

  def start_entrants_dropdown_menu(view_object)
    dropdown_items = view_object.ready_efforts.count_by(&:assumed_start_time_local).sort.map do |time, effort_count|
      {
        name: "(#{effort_count}) scheduled at #{l(time, format: :full_day_military_and_zone)}",
        link: start_efforts_form_event_group_path(view_object.event_group, effort_count: effort_count, scheduled_start_time_local: time),
        data: { turbo_frame: "form_modal" }
      }
    end

    build_dropdown_menu("Start Entrants", dropdown_items, button: true, button_type: "success")
  end

  def admin_dropdown_menu(view_object)
    dropdown_items = [
      { name: "Construction",
        link: setup_event_group_path(view_object.event_group),
        active: action_name == "setup" },
      { name: "Reconcile",
        link: reconcile_event_group_path(view_object.event_group),
        active: action_name == "reconcile" },
      { name: "Roster",
        link: roster_event_group_path(view_object.event_group),
        active: action_name == "roster" && !params[:problem] },
      { name: "Problems",
        link: roster_event_group_path(view_object.event_group, problem: true),
        active: action_name == "roster" && params[:problem] },
      { name: "Stats",
        link: stats_event_group_path(view_object.event_group),
        active: controller_name == "event_groups" && action_name == "stats" },
      { name: "Finish Line",
        link: finish_line_event_group_path(view_object.event_group),
        active: controller_name == "event_groups" && action_name == "finish_line" },
    ]
    build_dropdown_menu("Admin", dropdown_items, class: "nav-item")
  end

  def live_dropdown_menu(view_object)
    dropdown_items = [
      { name: "Time Entry",
        link: live_entry_live_event_group_path(view_object.event_group),
        active: action_name == "live_entry",
        visible: view_object.available_live },
      { name: "Drops",
        link: drop_list_event_group_path(view_object.event_group),
        active: action_name == "drop_list" },
      { name: "Progress",
        link: progress_report_live_event_path(view_object.event),
        active: action_name == "progress_report" },
      { name: "Aid Stations",
        link: aid_station_report_live_event_path(view_object.event),
        active: action_name == "aid_station_report" },
      { name: "Aid Detail",
        link: aid_station_detail_live_event_path(view_object.event),
        active: action_name == "aid_station_detail" }
    ]
    build_dropdown_menu("Live", dropdown_items, class: "nav-item")
  end

  def results_dropdown_menu(view_object)
    dropdown_items = [
      { name: "Full",
        link: spread_event_path(view_object.event),
        active: action_name == "spread" },
      { name: "Summary",
        link: summary_event_path(view_object.event),
        active: action_name == "summary" && !(params[:finished] == "true") },
      { name: "Finishers",
        link: summary_event_path(view_object.event, finished: true),
        active: action_name == "summary" && params[:finished] == "true" },
      { name: "Finish history",
        link: finish_history_event_path(view_object.event),
        active: action_name == "finish_history" },
      { name: "Podium",
        link: podium_event_path(view_object.event),
        active: action_name == "podium" },
      { name: "Follow",
        link: follow_event_group_path(view_object.event_group),
        active: action_name == "follow" },
      { name: "Traffic",
        link: traffic_event_group_path(view_object.event_group),
        active: action_name == "traffic" }
    ]
    build_dropdown_menu("Results", dropdown_items, class: "nav-item")
  end

  def raw_times_dropdown_menu(view_object)
    dropdown_items = [
      { name: "List",
        link: raw_times_event_group_path(view_object.event_group),
        active: action_name == "raw_times" },
      { name: "Splits",
        link: split_raw_times_event_group_path(view_object.event_group),
        active: action_name == "split_raw_times" }
    ]
    build_dropdown_menu("Raw Times", dropdown_items, class: "nav-item")
  end

  def lottery_entrant_service_review_dropdown(status: "under_review")
    items = [
      { text: "Under review", status: "under_review" },
      { text: "Accepted", status: "accepted" },
      { text: "Rejected", status: "rejected" },
    ]

    dropdown_items = items.map do |item|
      { name: item[:text],
        link: request.params.merge(status: item[:status]),
        data: {
          turbo_stream: true,
          turbo_method: :get,
        },
        active: item[:status] == status }
    end

    build_dropdown_menu(nil, dropdown_items, button: true)
  end

  def check_in_filter_dropdown
    items = [{ icon_name: "circle-exclamation", type: :solid, text: "Problems", problem: true },
             { icon_name: "circle-question", type: :solid, text: "Unreconciled", unreconciled: true },
             { icon_name: "square", type: :regular, text: "Not checked", checked_in: false, started: false },
             { icon_name: "check-square", type: :regular, text: "Checked in", checked_in: true, started: false },
             { icon_name: "caret-square-right", type: :regular, text: "Started", started: true },
             { icon_name: "asterisk", type: :solid, text: "All" }]

    dropdown_items = items.map do |item|
      { name: fa_icon(item[:icon_name], text: item[:text], type: item[:type]),
        link: request.params.merge(
          checked_in: item[:checked_in],
          started: item[:started],
          unreconciled: item[:unreconciled],
          problem: item[:problem],
          filter: { search: "" },
          page: nil
        ),
        active: params[:checked_in]&.to_boolean == item[:checked_in] &&
          params[:started]&.to_boolean == item[:started] &&
          params[:unreconciled]&.to_boolean == item[:unreconciled] &&
          params[:problem]&.to_boolean == item[:problem] }
    end

    build_dropdown_menu(nil, dropdown_items, button: true)
  end

  def raw_time_filter_dropdown
    items = [{ icon_name: "hand-paper", type: :solid, text: "Stopped", stopped: true, reviewed: nil, matched: nil },
             { icon_name: "cloud-download-alt", type: :solid, text: "Reviewed", stopped: nil, reviewed: true, matched: nil },
             { icon_name: "cloud-upload-alt", type: :solid, text: "Unreviewed", stopped: nil, reviewed: false, matched: nil },
             { icon_name: "check-square", type: :solid, text: "Matched", stopped: nil, reviewed: nil, matched: true },
             { icon_name: "square", type: :solid, text: "Unmatched", stopped: nil, reviewed: nil, matched: false },
             { icon_name: "asterisk", type: :solid, text: "All", stopped: nil, reviewed: nil, matched: nil }]

    dropdown_items = items.map do |item|
      { name: fa_icon(item[:icon_name], text: item[:text], type: item[:type]),
        link: request.params.merge(
          stopped: item[:stopped],
          reviewed: item[:reviewed],
          matched: item[:matched],
          page: nil
        ),
        active: params[:stopped]&.to_boolean == item[:stopped] &&
          params[:reviewed]&.to_boolean == item[:reviewed] &&
          params[:matched]&.to_boolean == item[:matched] }
    end

    build_dropdown_menu(nil, dropdown_items, button: true)
  end

  def summary_filter_dropdown
    items = [{ text: "All", finished: nil },
             { text: "Finished", finished: true },
             { text: "Unfinished", finished: false }]

    dropdown_items = items.map do |item|
      { name: item[:text],
        link: request.params.merge(finished: item[:finished], page: nil),
        active: params[:finished]&.to_boolean == item[:finished] }
    end

    build_dropdown_menu(nil, dropdown_items, button: true)
  end

  def historical_facts_kinds_filter_dropdown
    items = [
      { text: "All kinds", kinds: [] },
      { text: "Outcome", kinds: %w[dns dnf finished] },
      { text: "Volunteer", kinds: %w[volunteer_year volunteer_year_major volunteer_multi volunteer_multi_reported] },
      { text: "Reported", kinds: %w[qualifier_finish emergency_contact previous_names volunteer_multi_reported] },
      { text: "Legacy", kinds: %w[lottery_ticket_count_legacy lottery_division_legacy] },
      { text: "Lottery Application", kinds: %w[lottery_application] },
    ]

    dropdown_items = items.map do |item|
      {
        name: item[:text],
        link: request.params.merge(kind: item[:kinds], page: nil),
        active: (params[:kind].presence == item[:kinds].presence)
      }
    end

    build_dropdown_menu(nil, dropdown_items, button: true)
  end

  def historical_facts_reconciled_filter_dropdown
    items = [
      { icon_name: "circle", type: :regular, color: :secondary, text: "All", reconciled: nil },
      { icon_name: "circle-minus", type: :solid, color: :warning, text: "Unreconciled", reconciled: false },
      { icon_name: "circle-check", type: :regular, color: :success, text: "Reconciled", reconciled: true },
    ]

    dropdown_items = items.map do |item|
      {
        name: fa_icon(item[:icon_name], text: item[:text], type: item[:type], color: item[:color]),
        link: request.params.merge(
          reconciled: item[:reconciled],
          page: nil
        ),
        active: params[:reconciled]&.to_boolean == item[:reconciled]
      }
    end

    build_dropdown_menu(nil, dropdown_items, button: true)
  end

  def explore_dropdown_menu(view_object)
    dropdown_items = [
      { name: "All-time best (#{view_object.course.name})",
        link: organization_course_best_efforts_path(view_object.organization, view_object.course) },
    ]

    view_object.course_groups.each do |course_group|
      item = { role: :separator }
      dropdown_items << item

      item = { name: "All-time best (#{course_group.name})",
               link: organization_course_group_best_efforts_path(view_object.organization, course_group) }
      dropdown_items << item

      item = { name: "All finishers (#{course_group.name})",
               link: organization_course_group_finishers_path(view_object.organization, course_group) }
      dropdown_items << item
    end

    dropdown_items += [
      { role: :separator },
      { name: "Plan my effort",
        link: plan_effort_organization_course_path(view_object.organization, view_object.course) },
      { name: "Cutoff analysis",
        link: cutoff_analysis_organization_course_path(view_object.organization, view_object.course) },
    ]
    build_dropdown_menu("Explore", dropdown_items, button: true)
  end

  def effort_actions_dropdown_menu(view_object)
    dropdown_items = [
      { name: "Set Data Status",
        link: set_data_status_effort_path(view_object.effort),
        data: { turbo_method: :patch } },
      { role: :separator },
      { name: "Edit Times of Day",
        link: edit_split_times_effort_path(view_object.effort, display_style: :military_time) },
      { name: "Edit Dates and Times",
        link: edit_split_times_effort_path(view_object.effort, display_style: :absolute_time_local) },
      { name: "Edit Elapsed Times",
        link: edit_split_times_effort_path(view_object.effort, display_style: :elapsed_time) },
      { role: :separator },
      { name: "Edit Entrant",
        link: edit_effort_path(view_object.effort),
        data: { turbo_frame: "form_modal" } },
    ]
    build_dropdown_menu("Actions", dropdown_items, button: true)
  end

  def event_series_actions_dropdown_menu(view_object)
    dropdown_items = [
      { name: "Edit",
        link: edit_organization_event_series_path(view_object.organization, view_object.event_series) },
      { role: :separator },
      { name: "Delete event series",
        link: organization_event_series_path(view_object.organization, view_object.event_series),
        data: {
          turbo_confirm: "This action cannot be undone. Proceed?",
          turbo_method: :delete,
        },
        class: "text-danger" }
    ]
    build_dropdown_menu("Actions", dropdown_items, button: true)
  end

  def course_group_actions_dropdown_menu(view_object)
    dropdown_items = [
      { name: "Edit",
        link: edit_organization_course_group_path(view_object.organization, view_object.course_group) },
      { role: :separator },
      { name: "Delete course group",
        link: organization_course_group_path(view_object.organization, view_object.course_group),
        data: {
          turbo_confirm: "This action cannot be undone. Proceed?",
          turbo_method: :delete,
        },
        class: "text-danger" }
    ]
    build_dropdown_menu("Actions", dropdown_items, button: true)
  end

  def person_actions_dropdown_menu(view_object)
    dropdown_items = [
      {
        name: "Edit",
        link: edit_person_path(view_object.person),
      },
      {
        name: "Merge with",
        link: merge_person_path(view_object.person),
        visible: view_object.current_user.admin?,
      },
      {
        role: :separator,
        visible: view_object.current_user.admin?,
      },
      {
        name: "Delete person",
        link: person_path(view_object.person),
        visible: view_object.current_user.admin?,
        method: :delete,
        data: { confirm: "This action cannot be undone. Proceed?" },
        class: "text-danger",
      }
    ]
    build_dropdown_menu("Actions", dropdown_items, button: true)
  end

  def gender_dropdown_menu(view_object)
    genders = view_object.relevant_genders
    genders.unshift("combined")

    dropdown_items = genders.map do |gender|
      {
        name: gender.titleize,
        link: request.params.merge(filter: { gender: gender }, page: nil),
        active: view_object.gender_text == gender,
        disabled: view_object.gender_text == gender,
      }
    end

    build_dropdown_menu(nil, dropdown_items, button: true)
  end

  def display_style_dropdown_menu(view_object)
    dropdown_items = view_object.display_style_hash.map do |style, text|
      { name: text,
        link: request.params.merge(display_style: style),
        active: view_object.display_style.to_s == style.to_s }
    end
    build_dropdown_menu(nil, dropdown_items, button: true)
  end

  def event_actions_dropdown(event)
    dropdown_items = [
      { name: "Establish Drops",
        link: set_stops_event_path(event),
        data: {
          turbo_method: :put,
          turbo_confirm: "NOTE: For every effort that is unfinished, this will flag the effort as having stopped " +
            "at the last aid station for which times are available. Are you sure you want to proceed?" } },
      { name: "Shift start time",
        link: edit_start_time_event_path(event),
        visible: current_user.admin?,
        data: { "turbo-frame" => "_top" } },
      { role: :separator },
      { name: "Export Finishers List",
        link: export_event_path(event, format: :csv, export_format: :finishers) },
      { name: "Export to ITRA",
        link: export_event_path(event, format: :csv, export_format: :itra) },
      { name: "Export to Ultrasignup",
        link: export_event_path(event, format: :csv, export_format: :ultrasignup) }
    ]
    build_dropdown_menu(fa_icon("gear"), dropdown_items, button: true)
  end

  def event_group_actions_dropdown(view_object)
    dropdown_items = [
      {
        name: "Edit/Delete Group",
        link: edit_organization_event_group_path(view_object.organization, view_object.event_group),
      },
      {
        name: "Duplicate Group",
        link: new_duplicate_event_group_path(existing_id: view_object.event_group.id),
        visible: view_object.events.present?,
      },
      {
        role: :separator,
        visible: view_object.events.present?,
      },
      {
        name: "Make Public or Private",
        link: setup_summary_event_group_path(view_object.event_group),
        visible: view_object.events.present?,
      },
      {
        name: "Enable or Disable Live",
        link: setup_summary_event_group_path(view_object.event_group),
        visible: view_object.events.present?,
      },
      {
        role: :separator,
      },
      {
        name: "Add/Remove Stewards",
        link: organization_path(view_object.organization, display_style: "stewards"),
      },
    ]
    build_dropdown_menu("Group Actions", dropdown_items, button: true)
  end

  def historical_facts_import_dropdown(view_object)
    dropdown_items = [
      { name: "Standard format",
        link: new_import_job_path(import_job: { parent_type: "Organization", parent_id: view_object.organization.id, format: :historical_facts }) },
      { name: "Hardrock legacy format",
        link: new_import_job_path(import_job: { parent_type: "Organization", parent_id: view_object.organization.id, format: :hardrock_historical_facts }) },
      { name: "Ultrasignup format",
        link: new_import_job_path(import_job: { parent_type: "Organization", parent_id: view_object.organization.id, format: :ultrasignup_historical_facts }) },
      { name: "Ultrasignup order id compare",
        link: new_import_job_path(import_job: { parent_type: "Organization", parent_id: view_object.organization.id, format: :ultrasignup_order_id_compare }) },
    ]

    build_dropdown_menu("Import", dropdown_items, button: true)
  end

  def setup_entrants_import_dropdown(view_object)
    elapsed_time_event_items = view_object.events.map do |event|
      event_suffix = view_object.events.many? ? "for #{event.guaranteed_short_name}" : nil

      {
        name: ["Entrants with elapsed times", event_suffix].compact.join(" "),
        link: new_import_job_path(import_job: { parent_type: "Event", parent_id: event.id, format: :event_entrants_with_elapsed_times }),
      }
    end
    military_time_event_items = view_object.events.map do |event|
      event_suffix = view_object.events.many? ? "for #{event.guaranteed_short_name}" : nil

      {
        name: ["Entrants with military times", event_suffix].compact.join(" "),
        link: new_import_job_path(import_job: { parent_type: "Event", parent_id: event.id, format: :event_entrants_with_military_times }),
      }
    end

    dropdown_items = [
      { name: "Event Group Entrants",
        link: new_import_job_path(import_job: { parent_type: "EventGroup", parent_id: view_object.event_group.id, format: :event_group_entrants }) },
      { role: :separator },
      *elapsed_time_event_items,
      { role: :separator },
      *military_time_event_items,
    ]

    build_dropdown_menu("Import", dropdown_items, button: true)
  end

  def roster_actions_dropdown(view_object)
    dropdown_items = [
      { name: "Reconcile efforts",
        link: reconcile_event_group_path(view_object.event_group) },
      { name: "Set data status",
        link: set_data_status_event_group_path(view_object.event_group),
        method: :patch },
      { role: :separator },
      { name: "Import entrants",
        link: new_import_job_path(import_job: { parent_type: "EventGroup", parent_id: view_object.event_group.id, format: :event_group_entrants }) }
    ]
    build_dropdown_menu("Actions", dropdown_items, button: true)
  end

  def split_name_dropdown(view_object, param: :parameterized_split_name)
    dropdown_items = view_object.ordered_split_names.map do |split_name|
      { name: split_name,
        link: request.params.merge(param => split_name.parameterize),
        active: split_name.parameterize == view_object.split_name&.parameterize }
    end

    build_dropdown_menu(nil, dropdown_items, button: true)
  end

  def split_name_filter_dropdown(view_object, param: :parameterized_split_name)
    default_item_filter = (request.params[:filter] || {}).except(param)
    default_item = { name: "All Splits",
                     link: request.params.merge(filter: default_item_filter, page: nil),
                     active: view_object.split_name.parameterize == "all-splits" }
    dropdown_items = view_object.ordered_split_names.map do |split_name|
      { name: split_name,
        link: request.params.deep_merge(filter: { param => split_name.parameterize }, page: nil),
        active: split_name.parameterize == view_object.split_name.parameterize }
    end
    dropdown_items.unshift(default_item)

    build_dropdown_menu(nil, dropdown_items, button: true)
  end

  def sub_split_kind_dropdown(view_object)
    dropdown_items = view_object.sub_split_kinds.map do |kind|
      { name: kind.titleize,
        link: request.params.merge(sub_split_kind: kind.parameterize),
        active: kind.parameterize == view_object.sub_split_kind.parameterize }
    end
    build_dropdown_menu(nil, dropdown_items, button: true)
  end

  def traffic_band_width_dropdown(view_object)
    dropdown_items = view_object.suggested_band_widths.map do |band_width|
      { name: pluralize(band_width / 1.minute, "minute"),
        link: request.params.merge(band_width: band_width),
        active: band_width == view_object.band_width }
    end
    build_dropdown_menu(nil, dropdown_items, button: true)
  end
end
