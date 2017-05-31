namespace :pull_event do
  desc 'Pulls and imports data from an outside source into an event'
  task :race_result, [:event_id, :rr_event_id, :rr_contest_id] => :environment do |_, args|
    start_time = Time.current

    event = Event.find_by(id: args[:event_id])
    abort("Aborted: Event id #{args[:event_id]} not found") unless event
    puts "Located event: #{event.name}"

    uri = DataImport::RaceResult::UriBuilder.new(args[:rr_event_id], args[:rr_contest_id]).full_uri
    importer = DataImport::Importer.new(uri, :race_result, event: event, strict: false, current_user_id: 1)
    abort("Importer could not be created") unless importer
    importer.import
    if importer.errors
      puts "Returned errors: #{importer.errors}"
    end
    puts "Imported #{importer.valid_records.size} records"
    puts "Deleted #{importer.destroyed_records.size} records"
    puts "Discarded #{importer.discarded_records.size} records"
    puts "Failed to import #{importer.invalid_records.size} records"

    elapsed_time = Time.current - start_time
    puts "\nFinished pull_event:race_result for event: #{event.name} from #{uri} in #{elapsed_time} seconds"
  end
end
