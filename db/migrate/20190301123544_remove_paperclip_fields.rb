class RemovePaperclipFields < ActiveRecord::Migration[5.2]
  def change
    remove_column :efforts, :photo_file_name, :string
    remove_column :efforts, :photo_content_type, :string
    remove_column :efforts, :photo_file_size, :string
    remove_column :efforts, :photo_updated_at, :datetime

    remove_column :people, :photo_file_name, :string
    remove_column :people, :photo_content_type, :string
    remove_column :people, :photo_file_size, :string
    remove_column :people, :photo_updated_at, :datetime

    remove_column :partners, :banner_file_name, :string
    remove_column :partners, :banner_content_type, :string
    remove_column :partners, :banner_file_size, :string
    remove_column :partners, :banner_updated_at, :datetime

    remove_column :courses, :gpx_file_name, :string
    remove_column :courses, :gpx_content_type, :string
    remove_column :courses, :gpx_file_size, :string
    remove_column :courses, :gpx_updated_at, :datetime
  end
end
