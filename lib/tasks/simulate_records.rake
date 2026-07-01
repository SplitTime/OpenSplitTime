namespace :simulate do
  desc "Duplicate an event group with N in-progress runners as of a cutoff time"
  task :in_progress, [:event_group_id, :cutoff, :count] => :environment do |_, args|
    if args.event_group_id.blank? || args.cutoff.blank?
      abort "Usage: rake simulate:in_progress[event_group_id, cutoff, count]"
    end

    source_event_group =
      begin
        EventGroup.friendly.find(args.event_group_id)
      rescue ActiveRecord::RecordNotFound
        abort "Event group '#{args.event_group_id}' not found"
      end

    count = (args.count || 40).to_i
    cutoff_time = Time.use_zone(source_event_group.home_time_zone) { Time.zone.parse(args.cutoff.to_s) }
    abort "Could not parse cutoff time '#{args.cutoff}'" if cutoff_time.nil?

    puts "Simulating '#{source_event_group.name}' with #{count} runners per event, in progress as of #{cutoff_time}..."

    result = SimulateInProgressEventGroup.perform(source_event_group: source_event_group, cutoff_time: cutoff_time,
                                                  count: count)

    puts "Created '#{result.new_event_group.name}' with #{result.simulated_efforts_count} efforts."
    puts "Setup: #{Rails.application.routes.url_helpers.setup_event_group_path(result.new_event_group)}"
  end
end
