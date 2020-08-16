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

  def link_to_toggle_raw_time_review(raw_time)
    if raw_time.reviewed_by? || raw_time.reviewed_at?
      reviewed_by = nil
      reviewed_at = nil
      tooltip_text = 'This raw time has been reviewed by a human. Click to mark it as not reviewed.'
      button_class = 'primary'
    else
      reviewed_by = current_user.id
      reviewed_at = Time.current
      tooltip_text = 'This raw time has not been reviewed by a human. Click to mark it as having been reviewed.'
      button_class = 'outline-secondary'
    end
    url = raw_time_path(raw_time, raw_time: {reviewed_by: reviewed_by, reviewed_at: reviewed_at}, referrer_path: request.params)
    options = {method: :patch,
               data: {toggle: :tooltip, placement: :bottom, 'original-title' => tooltip_text},
               class: "btn btn-#{button_class} has-tooltip click-spinner"}

    link_to fa_icon('glasses'), url, options
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

  def link_to_raw_time_associate(raw_time_id)
    url = raw_time_path(raw_time_id, raw_time: {disassociated_from_effort: false})
    tooltip = 'Associate this raw time with this effort'
    options = {method: :patch,
               data: {toggle: :tooltip,
                      placement: :bottom,
                      'original_title' => tooltip},
               id: "associate-raw-time-#{raw_time_id}",
               class: 'btn btn-sm btn-success has-tooltip'}

    link_to fa_icon(:plus_square), url, options
  end

  def link_to_raw_time_disassociate(raw_time_id)
    url = raw_time_path(raw_time_id, raw_time: {disassociated_from_effort: true})
    tooltip = 'Disassociate this raw time from this effort'
    options = {method: :patch,
               data: {toggle: :tooltip,
                      placement: :bottom,
                      'original_title' => tooltip},
               id: "disassociate-raw-time-#{raw_time_id}",
               class: 'btn btn-sm btn-danger has-tooltip'}

    link_to fa_icon(:minus_square), url, options
  end
end
