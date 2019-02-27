# frozen_string_literal: true

class EventParameters < BaseParameters

  # Do not add :event_group_id to this list. Events should get a new (or nil)
  # event_group_id through the EventsController#reassign action,
  # which does not rely on EventParameters.permitted.
  def self.permitted
    [:id, :slug, :course_id, :short_name, :start_time, :beacon_url, :available_live,
     :laps_required, :auto_live_times, :home_time_zone, :start_time_local, :results_template_id]
  end

  def self.permitted_query
    permitted + EffortParameters.permitted_query + LiveTimeParameters.permitted_query
  end
end
