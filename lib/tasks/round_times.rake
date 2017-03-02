namespace :round do
  desc 'For a given event_id, rounds intermediate times_from_start that end in :59 or :01 to :00'
  task :hardrock_style, [:event_id] => :environment do |_, args|
    start_time = Time.current
    event = Event.find(args[:event_id])
    split_times = event.split_times.intermediate
                      .where('mod(cast(split_times.time_from_start as integer), 60) IN (1, 59)')
    $stdout.sync = true
    puts "Found #{split_times.size} split times that need rounding"
    split_times.each do |st|
      if st.update(time_from_start: st.time_from_start.round_to_nearest(1.minute))
        print '.'
      else
        print 'X'
      end
    end
    elapsed_time = Time.current - start_time
    puts "\nFinished task in #{elapsed_time} seconds"
  end
end