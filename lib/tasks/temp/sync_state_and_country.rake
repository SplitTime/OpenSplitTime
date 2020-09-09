# This is a temporary rake task that should be deleted
# once it has been run in all environments.

require 'active_record'

namespace :temp do
  desc "sets state_name and country_name based on existing state and country codes"
  task :sync_state_and_country => :environment do
    puts "Syncing state_name and country_name columns"

    people = Person.where.not(country_code: nil)
    people_count = people.count

    puts "Found #{people_count} people having country_code info"

    progress_bar = ::ProgressBar.new(people_count)

    people.find_each do |person|
      progress_bar.increment!
      person.send(:sync_state)
      person.send(:sync_country)
      person.save!
    rescue ActiveRecordError => e
      puts "Could not set state and country for person #{person.id}:"
      puts e
    end
  end
end
