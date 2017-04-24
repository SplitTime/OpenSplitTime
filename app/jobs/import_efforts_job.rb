class ImportEffortsJob < ActiveJob::Base

  queue_as :default

  def perform(file_url, event, user_id, params, background_channel = nil)
    importer = EffortImporter.new(file_path: file_url, event: event, current_user_id: user_id,
                                  with_status: params[:with_status], with_times: params[:with_times],
                                  time_format: params[:time_format], background_channel: background_channel)
    importer.effort_import
    importer.effort_import_report # TODO store this in redis using user_id key & timestamp?
  end
end