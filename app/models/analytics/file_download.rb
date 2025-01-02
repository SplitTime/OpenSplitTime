class Analytics::FileDownload < ApplicationRecord
  self.table_name = "analytics_file_downloads"

  belongs_to :user
  belongs_to :record, polymorphic: true
end
