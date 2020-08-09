require 'active_record'

namespace :effort_segments do
  desc "sets effort segments for all efforts"
  task :set => :environment do
    puts "Setting effort segments for all efforts"

    efforts = Effort.all
    efforts_count = efforts.count

    puts "Found #{efforts_count} efforts"

    progress_bar = ::ProgressBar.new(efforts_count)

    efforts.find_each do |effort|
      progress_bar.increment!
      effort.set_effort_segments
    rescue ActiveRecordError => e
      puts "Could not set effort segments for effort #{effort.id}:"
      puts e
    end
  end

  desc "deletes effort segments for all efforts"
  task :delete => :environment do
    puts "Deleting effort segments for all efforts"

    efforts = Effort.all
    efforts_count = efforts.count

    puts "Found #{efforts_count} efforts"

    progress_bar = ::ProgressBar.new(efforts_count)

    efforts.find_each do |effort|
      progress_bar.increment!
      effort.delete_effort_segments
    rescue ActiveRecordError => e
      puts "Could not delete effort segments for effort #{effort.id}:"
      puts e
    end
  end
end
