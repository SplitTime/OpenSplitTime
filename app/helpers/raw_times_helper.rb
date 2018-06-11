# frozen_string_literal: true

module RawTimesHelper
  def link_to_raw_time_effort(raw_time)
    if raw_time.effort
      link_to raw_time.effort_full_name, effort_path(raw_time.effort)
    else
      raw_time.effort_full_name
    end
  end

  def link_to_raw_time_event(raw_time)
    if raw_time.event
      link_to raw_time.event.guaranteed_short_name, admin_event_path(raw_time.event)
    else
      raw_time.event.guaranteed_short_name
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
    if raw_time.pulled_by || raw_time.pulled_at
      link_to '', raw_time_path(raw_time, raw_time: {pulled_by: nil, pulled_at: nil}, referrer_path: request.params),
              method: :patch,
              data: {toggle: :tooltip, placement: :bottom, 'original-title' => 'Mark as not pulled'},
              class: 'fa fa-cloud-download btn btn-sm btn-primary has-tooltip'
    else
      link_to '', raw_time_path(raw_time, raw_time: {pulled_by: current_user.id, pulled_at: Time.current}, referrer_path: request.params),
              method: :patch,
              data: {toggle: :tooltip, placement: :bottom, 'original-title' => 'Mark as pulled'},
              class: 'fa fa-cloud-download btn btn-sm btn-default has-tooltip'
    end
  end

  def link_to_raw_time_delete(raw_time)
    link_to '', raw_time_path(raw_time, referrer_path: request.params),
            method: :delete,
            data: {confirm: 'We recommend that you keep a complete list of all time records, even those that are duplicated or incorrect. Are you sure you want to delete this record?'},
            class: 'fa fa-close btn btn-sm btn-danger'
  end
end
