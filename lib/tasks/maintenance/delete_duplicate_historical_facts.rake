# frozen_string_literal: true

namespace :maintenance do
  desc "Deletes duplicate historical facts"
  task delete_duplicate_historical_facts: :environment do
    puts "Attempting to delete duplicate historical facts"

    subquery = HistoricalFact.select("id, row_number() over (partition by personal_info_hash, kind, year order by id) as rank")
    duplicate_ids = HistoricalFact.select(:id).from(subquery, :historical_facts).where("rank > ?", 1).pluck(:id)

    puts "Found #{duplicate_ids.size} duplicate facts"

    progress_bar = ::ProgressBar.new(duplicate_ids.size)

    duplicate_ids.each do |id|
      progress_bar.increment!
      HistoricalFact.find(id).destroy
    rescue ActiveRecordError => e
      puts "Could not destroy historical_fact #{id}:"
      puts e
    end
  end
end
