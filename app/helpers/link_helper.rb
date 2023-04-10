# frozen_string_literal: true

module LinkHelper
  def link_to_monitor_mode(event_group)
    return_path = if event_group.blank?
                    organizations_path
                  elsif event_group.persisted? && event_group.events.exists?
                    roster_event_group_path(event_group)
                  else
                    organization_path(event_group.organization)
                  end

    link_to "Return to monitor mode", return_path, class: "btn btn-outline-light"
  end

  def link_to_reversing_sort_heading(column_heading, field_name, existing_sort)
    new_sort = field_name.to_s == existing_sort.to_s ? "-#{field_name}" : field_name
    link_to_sort_heading(column_heading, new_sort)
  end

  def link_to_sort_heading(column_heading, sort_string)
    link_to column_heading, request.params.merge(sort: sort_string)
  end
end
