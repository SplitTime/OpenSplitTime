namespace :maintenance do
  desc 'Delete all effort subscriptions for old events'
  task :sweep_subscriptions => :environment do
    puts "\nStarting"

    problem_subs = []
    obsolete_subs = Subscription.joins('join efforts on efforts.id = subscriptions.subscribable_id join events on events.id = efforts.event_id')
                      .where("subscriptions.subscribable_type = 'Effort' and events.start_time < ?", 1.year.ago)

    count = obsolete_subs.count
    if count > 0
      puts "Found #{count} obsolete subscriptions"
    else
      abort "No obsolete subscriptions found, exiting\n"
    end

    progress_bar = ::ProgressBar.new(count)

    obsolete_subs.find_in_batches do |subs|
      subs.each do |sub|
        problem_subs << sub.id unless sub.destroy
        progress_bar.increment!
      end
    end

    if problem_subs.present?
      puts "\nCould not destroy the following subscriptions: #{problem_subs.join(', ')}"
    else
      puts "\nAll obsolete subscriptions were destroyed"
    end
  end
end
