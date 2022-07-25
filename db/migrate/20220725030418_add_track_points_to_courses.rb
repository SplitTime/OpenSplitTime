class AddTrackPointsToCourses < ActiveRecord::Migration[7.0]
  def change
    add_column :courses, :track_points, :json
  end
end
