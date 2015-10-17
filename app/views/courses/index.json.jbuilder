json.array!(@courses) do |course|
  json.extract! course, :id, :course_id, :course_name, :start_elevation, :start_location_name, :end_location_name
  json.url course_url(course, format: :json)
end
