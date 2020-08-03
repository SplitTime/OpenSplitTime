# This is a temporary rake task that should be deleted
# once it has been run in all environments.

require 'active_record'

namespace :temp do
  desc "calculates elapsed_seconds for all split times"
  task :initialize_elapsed_seconds => :environment do
    puts "Initializing the elapsed_seconds column"

    efforts = Effort.all
    efforts_count = efforts.count

    puts "Found #{efforts_count} efforts"

    progress_bar = ::ProgressBar.new(efforts_count)

    efforts.find_each do |effort|
      progress_bar.increment!
      effort.split_times.first&.send(:sync_elapsed_seconds)
    rescue ActiveRecordError => e
      puts "Could not initialize for effort #{effort.id}:"
      puts e
    end
  end
end
