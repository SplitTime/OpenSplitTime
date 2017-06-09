namespace :pull_event do
  desc 'Pulls and imports full event data including effort information from an outside source into an event'
  task :race_result_full, [:event_id, :rr_event_id, :rr_contest_id] => :environment do |_, args|
    Rake::Task['pull_event:race_result'].invoke(args[:event_id], args[:rr_event_id], args[:rr_contest_id], :race_result_full)
  end

  desc 'Pulls and imports time data from an outside source into an event having existing efforts'
  task :race_result_times, [:event_id, :rr_event_id, :rr_contest_id] => :environment do |_, args|
    Rake::Task['pull_event:race_result'].invoke(args[:event_id], args[:rr_event_id], args[:rr_contest_id], :race_result_times)
  end

  desc 'Pulls and imports event data from an outside source into an event using a specified format'
  task :race_result, [:event_id, :rr_event_id, :rr_contest_id, :format] => :environment do |_, args|
    start_time = Time.current

    event = Event.find_by(id: args[:event_id])
    abort("Aborted: Event id #{args[:event_id]} not found") unless event
    puts "Located event: #{event.name}"

    uri = DataImport::Helpers::RaceResultUriBuilder.new(args[:rr_event_id], args[:rr_contest_id]).full_uri
    importer = DataImport::Importer.new(uri, args[:format], event: event, strict: false, current_user_id: 1)
    abort("Importer could not be created") unless importer
    importer.import

    if importer.errors
      puts "Returned errors: #{importer.errors}"
    end

    puts "Imported #{importer.saved_records.size} records"
    puts "Deleted #{importer.destroyed_records.size} records"
    puts "Ignored #{importer.ignored_records.size} records"
    puts "Failed to import #{importer.invalid_records.size} records"
    puts "\nInvalid records:\n"
    importer.invalid_records.each do |record|
      puts "\n#{record.model_name.human}: #{record.errors.full_messages.join(', ')}\n"
      puts "#{record.attributes}\n"
      if record.respond_to?(:split_times)
        record.split_times.each do |split_time|
          if split_time.errors.present?
            puts "  Split time: #{split_time.errors.full_messages.join(', ')}\n"
            puts "  #{split_time.attributes}\n"
          end
        end
      end
    end

    elapsed_time = Time.current - start_time
    puts "\nFinished pull_event:race_result for event: #{event.name} from #{uri} in #{elapsed_time} seconds"
  end
end
