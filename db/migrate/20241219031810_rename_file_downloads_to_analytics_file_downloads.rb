class RenameFileDownloadsToAnalyticsFileDownloads < ActiveRecord::Migration[7.0]
  def change
    rename_table :file_downloads, :analytics_file_downloads
  end
end
