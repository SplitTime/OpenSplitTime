class EventParameters < BaseParameters

  def self.permitted
    [:id, :course_id, :organization_id, :name, :start_time, :concealed,
     :available_live, :beacon_url, :laps_required, :staging_id, :auto_live_times]
  end

  def self.permitted_query
    permitted + EffortParameters.permitted_query
  end
end
