namespace :round do
  desc 'For a given event_id, rounds intermediate times_from_start that end in :59 or :01 to :00'
  task :hardrock_style, [:event_id] => :environment do |_, args|
    start_time = Time.current

    event = Event.find_by(id: args[:event_id])
    abort("Aborted: Event id #{args[:event_id]} not found") unless event
    puts "Located event: #{event.name}"

    split_times = event.split_times.intermediate
                      .where('mod(cast(split_times.time_from_start as integer), 60) IN (1, 59)')
    puts "Found #{split_times.size} split times that need rounding"

    $stdout.sync = true
    split_times.each do |st|
      if st.update(time_from_start: st.time_from_start.round_to_nearest(1.minute))
        print '.'
      else
        print 'X'
      end
    end

    elapsed_time = Time.current - start_time
    puts "\nFinished round:hardrock_style for event: #{event.name} in #{elapsed_time} seconds"
  end

  desc 'For a given organization_id, performs round:hardrock_style on all events associated with the organization'
  task :organization_events, [:org_id] => :environment do |_, args|
    start_time = Time.current

    organization = Organization.find_by(id: args[:org_id])
    abort("Aborted: Organization id #{args[:org_id]} not found") unless organization
    puts "Located organization: #{organization.name}"

    events = organization.events
    puts "Located #{events.size} events for #{organization.name}"

    organization.events.each do |event|
      Rake::Task['round:hardrock_style'].reenable
      Rake::Task['round:hardrock_style'].invoke(event.id)
    end

    elapsed_time = Time.current - start_time
    puts "\nFinished round:organization_events in #{elapsed_time} seconds"
  end
end