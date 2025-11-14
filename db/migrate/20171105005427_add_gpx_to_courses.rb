class AddGpxToCourses < ActiveRecord::Migration[5.1]
  def change
    add_column :courses, :gpx_file_name,    :string
    add_column :courses, :gpx_content_type, :string
    add_column :courses, :gpx_file_size,    :integer
    add_column :courses, :gpx_updated_at,   :datetime
  end
end
