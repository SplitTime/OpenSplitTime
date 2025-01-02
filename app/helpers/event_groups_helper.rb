module EventGroupsHelper
  def button_to_event_group_disable_live(view_object)
    button_to "Disable Live Entry",
              organization_event_group_path(view_object.organization, view_object.event_group, event_group: { available_live: false }),
              method: :patch,
              data: { turbo_confirm: t("event_groups.setup.disable_live_confirm", event_group_name: view_object.event_group_name) },
              class: "btn btn-outline-success"
  end

  def button_to_event_group_enable_live(view_object)
    button_to "Enable Live Entry",
              organization_event_group_path(view_object.organization, view_object.event_group, event_group: { available_live: true }),
              method: :patch,
              data: { turbo_confirm: t("event_groups.setup.enable_live_confirm", event_group_name: view_object.event_group_name) },
              class: "btn btn-outline-success"
  end

  def button_to_event_group_make_public(view_object)
    button_to "Go Public",
              organization_event_group_path(view_object.organization, view_object.event_group, event_group: { concealed: false }),
              method: :patch,
              data: { turbo_confirm: t("event_groups.setup.make_public_confirm", event_group_name: view_object.event_group_name) },
              class: "btn btn-outline-success"
  end

  def button_to_event_group_make_private(view_object)
    button_to "Take Private",
              organization_event_group_path(view_object.organization, view_object.event_group, event_group: { concealed: true }),
              method: :patch,
              data: { turbo_confirm: t("event_groups.setup.make_private_confirm", event_group_name: view_object.event_group_name) },
              class: "btn btn-outline-success"
  end

  def link_to_reconcile_efforts(event_group)
    link_to "Reconcile",
            reconcile_event_group_path(event_group),
            class: "btn btn-outline-success"
  end

  def link_to_export_raw_times(view_object, split_name, csv_template)
    link_to "Export", export_raw_times_event_group_path(view_object.event_group, split_name: split_name, csv_template: csv_template, format: :csv),
            class: "btn btn-md btn-success"
  end

  def lap_and_time_builder(bib_row)
    bib_row.split_times.map do |st|
      lap_prefix = bib_row.single_lap ? "" : "Lap #{st.lap}:  "
      lap_prefix + st.military_time
    end.join("\n")
  end
end
