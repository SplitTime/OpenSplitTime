module LiveTimesHelper
  def link_to_live_time_effort(live_time)
    if live_time.effort
      link_to live_time.effort_full_name, effort_path(live_time.effort)
    else
      live_time.effort_full_name
    end
  end
end
