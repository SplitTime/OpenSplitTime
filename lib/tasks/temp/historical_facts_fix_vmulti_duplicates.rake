namespace :temp do
  desc "Changes imported volunteer_multi records to volunteer_multi_reported"
  task historical_facts_fix_vmulti_duplicates: :environment do
    puts "Changing volunteer_multi records to volunteer_multi_reported"

    historical_facts = HistoricalFact.where(kind: :volunteer_multi, year: 2024)
    hf_count = historical_facts.count

    puts "Found #{hf_count} historical facts to update"

    progress_bar = ::ProgressBar.new(hf_count)

    historical_facts.find_each do |fact|
      progress_bar.increment!
      fact.update(kind: :volunteer_multi_reported)
    rescue ActiveRecordError => e
      puts "Could not update record for HistoricalFact id: #{fact.id}"
      puts e
    end
  end
end
