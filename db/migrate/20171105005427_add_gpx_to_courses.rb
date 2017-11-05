class AddGpxToCourses < ActiveRecord::Migration[5.1]
  def change
    add_attachment :courses, :gpx
  end
end
