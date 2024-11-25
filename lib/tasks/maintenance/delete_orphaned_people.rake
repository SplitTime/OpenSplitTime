# frozen_string_literal: true

namespace :maintenance do
  desc "Deletes people who have no efforts"
  task delete_orphaned_people: :environment do
    puts "Attempting to delete all orphaned person records from the database"

    orphaned_people = ::Person.left_joins(:efforts, :historical_facts)
      .where(efforts: { person_id: nil }, historical_facts: { person_id: nil })
      .distinct
    orphan_count = orphaned_people.count

    puts "Found #{orphan_count} orphaned people"

    progress_bar = ::ProgressBar.new(orphan_count)

    orphaned_people.find_each do |person|
      progress_bar.increment!
      person.destroy
    rescue ActiveRecordError => e
      puts "Could not destroy person #{person.id}:"
      puts e
    end
  end
end
