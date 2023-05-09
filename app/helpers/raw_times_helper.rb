# frozen_string_literal: true

module RawTimesHelper
  def link_to_raw_time_effort(raw_time)
    if raw_time.effort
      link_to raw_time.effort_full_name, effort_path(raw_time.effort)
    else
      "--"
    end
  end

  def link_to_raw_time_split(raw_time)
    if raw_time.split
      raw_time.split_name
    else
      raw_time.split_name
    end
  end

  def button_to_raw_time_manage(url:, params:, method:, button_id:, button_type:, tooltip:, icon:, confirm: nil)
    html_options = {
      id: button_id,
      class: "btn btn-sm btn-#{button_type} m-1",
      method: method,
      params: params,
      data: {
        controller: "tooltip",
        bs_placement: :bottom,
        bs_original_title: tooltip,
        turbo_confirm: confirm,
        turbo_submits_with: fa_icon("spinner", class: "fa-spin"),
      },
    }

    button_to(url, html_options) { fa_icon(icon) }
  end

  def link_to_toggle_raw_time_review(raw_time)
    if raw_time.reviewed_at?
      params = { raw_time: { reviewed_by: nil, reviewed_at: nil } }
      tooltip = "This raw time has been reviewed by a human. Click to mark it as not reviewed."
      button_id = "set-unreviewed-raw-time-#{raw_time.id}"
      button_type = "primary"
      icon = "user-plus"
    else
      params = { raw_time: { reviewed_by: nil, reviewed_at: Time.current } }
      tooltip = "This raw time has not been reviewed by a human. Click to mark it as having been reviewed."
      button_id = "set-reviewed-raw-time-#{raw_time.id}"
      button_type = "outline-secondary"
      icon = "user-minus"
    end

    url = raw_time_path(raw_time, referrer_path: request.params)
    button_to_raw_time_manage(
      url: url,
      params: params,
      method: :patch,
      button_id: button_id,
      button_type: button_type,
      tooltip: tooltip,
      icon: icon,
    )
  end

  def link_to_raw_time_delete(raw_time)
    button_to_raw_time_manage(
      url: raw_time_path(raw_time, referrer_path: request.params),
      params: nil,
      method: :delete,
      button_id: "delete-raw-time-#{raw_time.id}",
      button_type: "outline-danger",
      tooltip: "Delete raw time",
      icon: "trash",
      confirm: "We recommend that you keep a complete list of all time records, even those that are duplicated or incorrect. Are you sure you want to delete this record?"
    )
  end

  def button_to_raw_time_match(split_time, raw_time_id, icon)
    if split_time.persisted?
      url = split_time_path(split_time)
      params = { split_time: { matching_raw_time_id: raw_time_id } }
      method = :patch
      tooltip = icon == :link ? "Match this raw time" : "Set this as the governing time"
    else
      url = create_split_time_from_raw_time_effort_path(split_time.effort_id)
      params = { split_time: { raw_time_id: raw_time_id, lap: split_time.lap } }
      method = :post
      tooltip = "Create a split time from this raw time"
    end

    button_to_raw_time_manage(
      url: url,
      params: params,
      method: method,
      button_id: "match-raw-time-#{raw_time_id}",
      button_type: "outline-success",
      tooltip: tooltip,
      icon: icon,
    )
  end

  def button_to_raw_time_unmatch(split_time, raw_time_id)
    button_to_raw_time_manage(
      url: raw_time_path(raw_time_id, effort_id: split_time.effort_id),
      params: { raw_time: { split_time_id: nil } },
      method: :patch,
      button_id: "unmatch-raw-time-#{raw_time_id}",
      button_type: "outline-danger",
      tooltip: "Un-match this raw time",
      icon: :unlink,
    )
  end

  def button_to_raw_time_associate(split_time, raw_time_id)
    button_to_raw_time_manage(
      url: raw_time_path(raw_time_id, effort_id: split_time.effort_id),
      params: { raw_time: { disassociated_from_effort: false } },
      method: :patch,
      button_id: "associate-raw-time-#{raw_time_id}",
      button_type: "outline-success",
      tooltip: "Associate this raw time with this effort",
      icon: :plus_square,
    )
  end

  def button_to_raw_time_disassociate(split_time, raw_time_id)
    button_to_raw_time_manage(
      url: raw_time_path(raw_time_id, effort_id: split_time.effort_id),
      params: { raw_time: { disassociated_from_effort: true } },
      method: :patch,
      button_id: "disassociate-raw-time-#{raw_time_id}",
      button_type: "outline-danger",
      tooltip: "Disassociate this raw time from this effort",
      icon: :minus_square,
    )
  end
end
