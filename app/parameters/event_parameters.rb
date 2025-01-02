class EventParameters < BaseParameters
  def self.permitted
    [
      :id,
      :slug,
      :course_id,
      :event_group_id,
      :short_name,
      :scheduled_start_time,
      :beacon_url,
      :available_live,
      :laps_required,
      :scheduled_start_time_local,
      :results_template_id,
      :notice_text,
      :lottery_id,
    ]
  end

  def self.permitted_query
    permitted + EffortParameters.permitted_query + LiveTimeParameters.permitted_query
  end
end
