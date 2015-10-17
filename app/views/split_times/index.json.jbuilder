json.array!(@split_times) do |split_time|
  json.extract! split_time, :id, :splittime_id, :effort_id, :split_id, :time_from_start, :data_status
  json.url split_time_url(split_time, format: :json)
end
