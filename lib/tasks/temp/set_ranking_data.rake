# This is a temporary rake task that should be deleted
# once it has been run in all environments.

require "active_record"
require "active_record/errors"

namespace :temp do
  desc "sets overall performance and status fields for all efforts"
  task set_ranking_data: :environment do
    Rails.application.eager_load!

    Event.find_each do |event|
      event.efforts.find_each do |effort|
        result = ::Results::SetEffortPerformanceData.perform!(effort.id)
        puts result.cmd_status
      end
    end

    puts "Finished updating efforts for all events"
  end
end
