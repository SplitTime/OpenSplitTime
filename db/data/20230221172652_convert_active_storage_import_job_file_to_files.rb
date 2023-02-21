# frozen_string_literal: true

class ConvertActiveStorageImportJobFileToFiles < ActiveRecord::Migration[7.0]
  def up
    ActiveStorage::Attachment.where(name: "file")
                             .where(record_type: "ImportJob")
                             .update_all(name: "files")
  end

  def down
    ActiveStorage::Attachment.where(name: "files")
                             .where(record_type: "ImportJob")
                             .update_all(name: "file")
  end
end
