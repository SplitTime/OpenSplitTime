json.split_times @split_times do |split_time|
  json.id               split_time.id
  json.time_from_start  split_time.time_from_start
  json.data_status      split_time.data_status
end
