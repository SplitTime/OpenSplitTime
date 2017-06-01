class ImportSplitsJob < ActiveJob::Base

  queue_as :default

  def perform(file_url, event, user_id)
    importer = SplitImporter.new(file_path: file_url, event: event, current_user_id: user_id)
    importer.split_import
    importer.split_import_report
  end
end
