class ImportWorker
  include Sidekiq::Worker

  def perform(file, event_id, user_id)
    event = Event.find(event_id)
    importer = EffortImporter.new(file, event, user_id)
    response[:effort_import] = importer.effort_import
    response[:effort_import_report] = importer.effort_import_report
    response[:errors] = importer.errors.messages[:effort_importer]
    response
  end

end