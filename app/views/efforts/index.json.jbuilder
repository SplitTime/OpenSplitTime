json.array!(@efforts) do |effort|
  json.extract! effort, :id, :effort_id, :event_id, :participant_id, :wave, :bib_number, :effort_city, :effort_state, :effort_country, :effort_age, :start_time, :official_finish
  json.url effort_url(effort, format: :json)
end
