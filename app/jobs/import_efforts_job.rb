class ImportEffortsJob < ActiveJob::Base

  queue_as :default

  def perform(file_url, event, user_id)
    importer = EffortImporter.new(file_url, event, user_id)
    importer.effort_import
    importer.effort_import_report
  end

end