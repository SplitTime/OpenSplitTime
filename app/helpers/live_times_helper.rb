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
end
