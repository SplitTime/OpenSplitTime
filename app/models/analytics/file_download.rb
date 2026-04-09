module Analytics
  class FileDownload < ApplicationRecord
    belongs_to :user
    belongs_to :record, polymorphic: true
  end
end
