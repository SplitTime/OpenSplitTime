json.event do
  json.id                @event.id
  json.name              @event.name
  json.course            @event.course
  json.first_start_time  @event.first_start_time
  json.race              @event.race
end
