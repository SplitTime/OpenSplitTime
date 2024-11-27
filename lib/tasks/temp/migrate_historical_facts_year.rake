# frozen_string_literal: true

namespace :temp do
  desc "Migrates year information from comments to year in historical_facts table"
  task migrate_historical_facts_year: :environment do
    puts "Migrating year information from comments to year"

    relevant_kinds = %w[dns dnf finished]

    historical_facts = HistoricalFact.where(kind: relevant_kinds)
    hf_count = historical_facts.count

    puts "Found #{hf_count} historical facts needing migration"

    progress_bar = ::ProgressBar.new(hf_count)

    historical_facts.find_each do |fact|
      progress_bar.increment!

      abort "Comments are not numeric for HistoricalFact id: #{fact.id}" unless fact.comments.numeric?

      comments = fact.comments
      fact.update(year: comments, comments: nil)
    rescue ActiveRecordError => e
      puts "Could not update record for HistoricalFact id: #{fact.id}"
      puts e
    end
  end
end
