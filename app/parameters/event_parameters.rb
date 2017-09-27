class EventParameters < BaseParameters

  def self.permitted
    [:id, :course_id, :event_group_id, :name, :short_name, :start_time, :beacon_url, :available_live,
     :laps_required, :staging_id, :auto_live_times, :home_time_zone, :start_time_in_home_zone]
  end

  def self.permitted_query
    permitted + EffortParameters.permitted_query
  end
end
