# frozen_string_literal: true

class EventParameters < BaseParameters

  def self.permitted
    [:id, :slug, :course_id, :event_group_id, :short_name, :start_time, :beacon_url, :available_live,
     :laps_required, :start_time_local, :results_template_id, :notice_text]
  end

  def self.permitted_query
    permitted + EffortParameters.permitted_query + LiveTimeParameters.permitted_query
  end
end
