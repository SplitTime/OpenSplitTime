# This is a temporary rake task that should be deleted
# once it has been run in all environments.

require 'active_record'
require 'active_record/errors'

namespace :temp do
  desc "sets state_name and country_name based on existing state and country codes"
  task :sync_state_and_country => :environment do
    Rails.application.eager_load!

    puts "Syncing state_name and country_name columns"

    people = Person.where.not(country_code: nil).where(country_name: nil)
    people_count = people.count

    puts "Found #{people_count} people needing state/country updates"

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
    
    puts "Finished syncing people"
    
    efforts = Effort.where.not(country_code: nil).where(country_name: nil)
    efforts_count = efforts.count

    puts "Found #{efforts_count} efforts needing state/country updates"

    progress_bar = ::ProgressBar.new(efforts_count)

    efforts.find_each do |effort|
      progress_bar.increment!
      effort.send(:sync_state)
      effort.send(:sync_country)
      effort.save!
    rescue ActiveRecordError => e
      puts "Could not set state and country for effort #{effort.id}:"
      puts e
    end

    puts "Finished syncing efforts"
  end
end
