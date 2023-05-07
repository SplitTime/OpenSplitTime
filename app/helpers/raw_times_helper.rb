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

  def link_to_toggle_raw_time_review(raw_time)
    if raw_time.reviewed_by? || raw_time.reviewed_at?
      reviewed_by = nil
      reviewed_at = nil
      tooltip_text = "This raw time has been reviewed by a human. Click to mark it as not reviewed."
      button_class = "primary"
    else
      reviewed_at = Time.current
      tooltip_text = "This raw time has not been reviewed by a human. Click to mark it as having been reviewed."
      button_class = "outline-secondary"
    end
    url = raw_time_path(raw_time, raw_time: { reviewed_by: reviewed_by, reviewed_at: reviewed_at }, referrer_path: request.params)
    options = { method: :patch,
                data: { controller: :tooltip,
                        bs_placement: :bottom,
                        bs_original_title: tooltip_text },
                class: "btn btn-#{button_class} click-spinner" }

    link_to fa_icon("glasses"), url, options
  end

  def link_to_raw_time_delete(raw_time)
    url = raw_time_path(raw_time, referrer_path: request.params)
    tooltip = "Delete raw time"
    options = { method: :delete,
                data: { confirm: "We recommend that you keep a complete list of all time records, even those that are duplicated or incorrect. Are you sure you want to delete this record?",
                        controller: :tooltip,
                        bs_placement: :bottom,
                        bs_original_title: tooltip },
                class: "btn btn-danger" }
    link_to fa_icon("trash"), url, options
  end

  def link_to_raw_time_match(split_time, raw_time_id, icon)
    if split_time.persisted?
      url = split_time_path(split_time)
      tooltip = icon == :link ? "Match this raw time" : "Set this as the governing time"
      method = :patch
      split_time_params = { split_time: { matching_raw_time_id: raw_time_id } }
    else
      url = create_split_time_from_raw_time_effort_path(split_time.effort_id)
      split_time_params = { split_time: { raw_time_id: raw_time_id, lap: split_time.lap } }
      tooltip = "Create a split time from this raw time"
      method = :post
    end

    html_options = {
      id: "match-raw-time-#{raw_time_id}",
      class: "btn btn-sm btn-outline-success m-1",
      method: method,
      params: split_time_params,
      data: {
        controller: "tooltip",
        bs_placement: :bottom,
        bs_original_title: tooltip,
        turbo_submits_with: fa_icon("spinner", class: "fa-spin"),
      },
    }

    button_to(url, html_options) { fa_icon(icon) }
  end

  def link_to_raw_time_unmatch(split_time, raw_time_id)
    url = raw_time_path(raw_time_id, effort_id: split_time.effort_id)
    tooltip = "Un-match this raw time"
    raw_time_params = { raw_time: { split_time_id: nil } }
    options = {
      id: "unmatch-raw-time-#{raw_time_id}",
      class: "btn btn-sm btn-outline-danger m-1",
      method: :patch,
      params: raw_time_params,
      data: {
        controller: "tooltip",
        bs_placement: :bottom,
        bs_original_title: tooltip,
        turbo_submits_with: fa_icon("spinner", class: "fa-spin"),
      },
    }

    button_to(url, options) { fa_icon(:unlink) }
  end

  def link_to_raw_time_associate(split_time, raw_time_id)
    url = raw_time_path(raw_time_id, effort_id: split_time.effort_id)
    tooltip = "Associate this raw time with this effort"
    raw_time_params = { raw_time: { disassociated_from_effort: false } }
    options = {
      id: "associate-raw-time-#{raw_time_id}",
      class: "btn btn-sm btn-outline-success m-1",
      method: :patch,
      params: raw_time_params,
      data: {
        controller: "tooltip",
        bs_placement: :bottom,
        bs_original_title: tooltip,
        turbo_submits_with: fa_icon("spinner", class: "fa-spin"),
      },
    }

    button_to(url, options) { fa_icon(:plus_square) }
  end

  def link_to_raw_time_disassociate(split_time, raw_time_id)
    url = raw_time_path(raw_time_id, effort_id: split_time.effort_id)
    tooltip = "Disassociate this raw time from this effort"
    raw_time_params = { raw_time: { disassociated_from_effort: true } }
    options = {
      id: "disassociate-raw-time-#{raw_time_id}",
      class: "btn btn-sm btn-outline-danger m-1",
      method: :patch,
      params: raw_time_params,
      data: {
        controller: "tooltip",
        bs_placement: :bottom,
        bs_original_title: tooltip,
        turbo_submits_with: fa_icon("spinner", class: "fa-spin"),
      },
    }

    button_to(url, options) { fa_icon(:minus_square) }
  end
end
