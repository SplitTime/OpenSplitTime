json.events @events do |event|
  json.id          event.id
  json.name        event.name
  json.course      event.course
  json.start_date  event.start_date
  json.race        event.race
end
