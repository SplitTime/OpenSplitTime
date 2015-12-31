json.course do
  json.id               @course.id
  json.name             @course.name
  json.start_location   @course.start_location
  json.end_location     @course.end_location
end
