json.array!(@events) do |event|
  json.extract! event, :id, :event_id, :event_name, :course_id, :start_date
  json.url event_url(event, format: :json)
end
