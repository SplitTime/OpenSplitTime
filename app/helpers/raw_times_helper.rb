# frozen_string_literal: true

module RawTimesHelper
  def link_to_raw_time_effort(raw_time)
    if raw_time.effort
      link_to raw_time.effort_full_name, effort_path(raw_time.effort)
    else
      '--'
    end
  end

  def link_to_raw_time_split(raw_time)
    if raw_time.split
      raw_time.split_name
    else
      raw_time.split_name
    end
  end

  def link_to_toggle_raw_time_pull(raw_time)
    if raw_time.pulled_by? || raw_time.pulled_at?
      pulled_by = nil
      pulled_at = nil
      tooltip_text = 'Mark as not pulled'
      button_class = 'primary'
    else
      pulled_by = current_user.id
      pulled_at = Time.current
      tooltip_text = 'Mark as pulled'
      button_class = 'outline-secondary'
    end
    url = raw_time_path(raw_time, raw_time: {pulled_by: pulled_by, pulled_at: pulled_at}, referrer_path: request.params)
    options = {method: :patch,
               data: {toggle: :tooltip, placement: :bottom, 'original-title' => tooltip_text},
               class: "btn btn-#{button_class} has-tooltip click-spinner"}

    link_to fa_icon('cloud-download-alt'), url, options
  end

  def link_to_raw_time_delete(raw_time)
    url = raw_time_path(raw_time, referrer_path: request.params)
    tooltip = 'Delete raw time'
    options = {method: :delete,
               data: {confirm: 'We recommend that you keep a complete list of all time records, even those that are duplicated or incorrect. Are you sure you want to delete this record?',
                      toggle: :tooltip,
                      placement: :bottom,
                      'original-title' => tooltip},
               class: 'btn btn-danger has-tooltip'}
    link_to fa_icon('trash'), url, options
  end

  def link_to_raw_time_match(split_time, raw_time_id, icon = :link)
    return unless split_time.persisted?

    url = split_time_path(split_time, split_time: {matching_raw_time_id: raw_time_id})
    tooltip = icon == :link ? 'Match this raw time' : 'Set this as the governing time'
    options = {method: :patch,
               data: {toggle: :tooltip,
                      placement: :bottom,
                      'original-title' => tooltip},
               id: "match-raw-time-#{raw_time_id}",
               class: 'btn btn-sm btn-success has-tooltip'}

    link_to fa_icon(icon), url, options
  end

  def link_to_raw_time_unmatch(raw_time_id)
    url = raw_time_path(raw_time_id, raw_time: {split_time_id: nil})
    tooltip = 'Un-match this raw time'
    options = {method: :patch,
               data: {toggle: :tooltip,
                      placement: :bottom,
                      'original-title' => tooltip},
               id: "unmatch-raw-time-#{raw_time_id}",
               class: 'btn btn-sm btn-danger has-tooltip'}

    link_to fa_icon(:unlink), url, options
  end
end
