# This is a temporary rake task that should be deleted
# once it has been run in all environments.

require 'active_record'

namespace :temp do
  desc "calculates elapsed_seconds for all split times"
  task :initialize_elapsed_seconds => :environment do
    puts "Initializing the elapsed_seconds column"

    starting_split_times = ::SplitTime.joins(:split).where(lap: 1, bitkey: ::SubSplit::IN_BITKEY, splits: {kind: :start})
    starting_split_times_count = starting_split_times.count

    puts "Found #{starting_split_times_count} starting split times"

    progress_bar = ::ProgressBar.new(starting_split_times_count)

    starting_split_times.find_each do |sst|
      progress_bar.increment!
      sst.send(:sync_effort_elapsed_seconds)
    rescue ActiveRecordError => e
      puts "Could not initialize for effort #{sst.effort_id}:"
      puts e
    end
  end
end
