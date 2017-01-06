class ImportEffortsJob < ActiveJob::Base

  queue_as :default

  def perform(file_url, event, user_id)
    importer = EffortImporter.new(file_path: file_url, event: event, current_user_id: user_id)
    importer.effort_import
    importer.effort_import_report # TODO store this in redis using user_id key & timestamp?
  end
end