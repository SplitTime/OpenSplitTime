# frozen_string_literal: true

class EventParameters < BaseParameters

  def self.permitted
    [:id, :slug, :course_id, :event_group_id, :name, :short_name, :start_time, :beacon_url, :available_live,
     :laps_required, :auto_live_times, :home_time_zone, :start_time_in_home_zone, :podium_template]
  end

  def self.permitted_query
    permitted + EffortParameters.permitted_query + LiveTimeParameters.permitted_query
  end
end
