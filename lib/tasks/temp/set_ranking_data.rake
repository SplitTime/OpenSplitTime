# This is a temporary rake task that should be deleted
# once it has been run in all environments.

require "active_record"
require "active_record/errors"

namespace :temp do
  desc "sets overall performance and status fields for all efforts"
  task set_ranking_data: :environment do
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
