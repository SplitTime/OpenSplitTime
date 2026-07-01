namespace :simulate do
  desc "Duplicate an event group as an in-progress race (start time + elapsed H:MM)"
  task :in_progress, [:event_group_id, :start_time, :elapsed, :count] => :environment do |_, args|
    if args.event_group_id.blank? || args.start_time.blank? || args.elapsed.blank?
      abort "Usage: rake simulate:in_progress[event_group_id, start_time, elapsed, count]\n  " \
            "e.g. rake simulate:in_progress[high-lonesome-100, \"2026-07-01 06:00\", 6:30, 40]"
    end

    source_event_group =
      begin
        EventGroup.friendly.find(args.event_group_id)
      rescue ActiveRecord::RecordNotFound
        abort "Event group '#{args.event_group_id}' not found"
      end

    start_time = Time.use_zone(source_event_group.home_time_zone) { Time.zone.parse(args.start_time.to_s) }
    abort "Could not parse start time '#{args.start_time}'" if start_time.nil?

    unless args.elapsed.to_s.match?(/\A\d+(:\d+){0,2}\z/)
      abort "Could not parse elapsed '#{args.elapsed}' (use H:MM, e.g. 6:30)"
    end
    hours, minutes, seconds = args.elapsed.split(":").map(&:to_i)
    elapsed_seconds = hours.hours + minutes.to_i.minutes + seconds.to_i.seconds

    # NB: use args[:count], not args.count — Rake::TaskArguments includes Enumerable, so args.count
    # returns the number of arguments (Enumerable#count), not the :count value.
    count = (args[:count] || 40).to_i

    puts "Simulating '#{source_event_group.name}': start #{start_time}, #{args.elapsed} into the race, " \
         "#{count} runners per event..."
    result = SimulateInProgressEventGroup.perform(source_event_group: source_event_group, start_time: start_time,
                                                  elapsed_seconds: elapsed_seconds, count: count)

    puts "Created '#{result.new_event_group.name}' with #{result.simulated_efforts_count} efforts."
    puts "Setup: #{Rails.application.routes.url_helpers.setup_event_group_path(result.new_event_group)}"
  end
end
