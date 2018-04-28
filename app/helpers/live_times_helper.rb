# frozen_string_literal: true

module LiveTimesHelper
  def link_to_live_time_effort(live_time)
    if live_time.effort
      link_to live_time.effort_full_name, effort_path(live_time.effort)
    else
      live_time.effort_full_name
    end
  end

  def link_to_live_time_split(live_time)
    if live_time.aid_station
      link_to live_time.split_base_name, times_aid_station_path(live_time.aid_station, sub_split_kind: live_time.sub_split_kind)
    else
      '[Station not found]'
    end
  end

  def link_to_toggle_live_time_pull(live_time)
    if live_time.pulled_by || live_time.pulled_at
      link_to '', live_time_path(live_time, live_time: {pulled_by: nil, pulled_at: nil}, referrer_path: request.params),
              method: :patch,
              data: {toggle: :tooltip, placement: :bottom, 'original-title' => 'Mark as not pulled'},
              class: 'fa fa-cloud-download btn btn-sm btn-primary has-tooltip'
    else
      link_to '', live_time_path(live_time, live_time: {pulled_by: current_user.id, pulled_at: Time.current}, referrer_path: request.params),
              method: :patch,
              data: {toggle: :tooltip, placement: :bottom, 'original-title' => 'Mark as pulled'},
              class: 'fa fa-cloud-download btn btn-sm btn-default has-tooltip'
    end
  end

  def link_to_toggle_live_time_match(live_time)
    if live_time.split_time_id
      link_to '', live_time_path(live_time, live_time: {split_time_id: nil}, referrer_path: request.params),
              method: :patch,
              data: {toggle: :tooltip, placement: :bottom, 'original-title' => 'Unlink from matching split time', confirm: 'Are you sure?'},
              class: 'fa fa-exchange btn btn-sm btn-success has-tooltip'
    else
      link_to '', live_time_path(live_time, live_time: {pulled_by: current_user.id, pulled_at: Time.current}, referrer_path: request.params),
              method: :patch,
              disabled: true,
              class: 'fa fa-exchange btn btn-sm btn-default'
    end
  end

  def link_to_live_time_delete(live_time)
    link_to '', live_time_path(live_time, referrer_path: request.params),
            method: :delete,
            data: {confirm: 'We recommend that you keep a complete list of all time records, even those that are duplicated or incorrect. Are you sure you want to delete this record?'},
            class: 'fa fa-close btn btn-sm btn-danger'
  end
end
