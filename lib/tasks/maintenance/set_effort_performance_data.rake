# This rake task sets effort performance data on all efforts.
# It may be run whenever effort performance data is out of sync,
# for example, if needed to backfill a new performance column.

require "active_record"
require "active_record/errors"

namespace :maintenance do
  desc "sets overall performance and status fields for all efforts"
  task set_effort_performance_data: :environment do
    Rails.application.eager_load!

    efforts = ::Effort.all
    efforts_count = efforts.count

    puts "Found #{efforts_count} efforts"

    progress_bar = ::ProgressBar.new(efforts_count)

    Effort.find_each do |effort|
      progress_bar.increment!
      ::Results::SetEffortPerformanceData.perform!(effort.id)
    end

    puts "Finished updating #{efforts_count} efforts"
  end
end
