json.split_time do
  json.id               @split_time.id
  json.effort           @split_time.effort
  json.split            @split_time.split
  json.time_from_start  @split_time.time_from_start
  json.data_status      @split_time.data_status
end
