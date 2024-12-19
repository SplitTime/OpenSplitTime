# frozen_string_literal: true

namespace :temp do
  desc "Migrates lottery_entrants.service_completed_date to lotteries_entrant_service_detail.completed_date"
  task migrate_service_completed_date: :environment do
    puts "Migrating lottery_entrants.service_completed_date to lotteries_entrant_service_detail.completed_date"

    entrants = LotteryEntrant.where.not(service_completed_date: nil)
    entrants_count = entrants.count

    puts "Found #{entrants_count} lottery entrants needing migration"

    progress_bar = ::ProgressBar.new(entrants_count)

    entrants.find_each do |entrant|
      progress_bar.increment!

      service_detail = entrant.service_detail || entrant.create_service_detail
      service_detail.update(completed_date: entrant.service_completed_date)
    rescue ActiveRecordError => e
      puts "Could not update record for entrant id: #{entrant.id}"
      puts e
    end
  end
end
