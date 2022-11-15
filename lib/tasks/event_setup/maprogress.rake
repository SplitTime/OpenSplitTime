# frozen_string_literal: true

namespace :event_setup do
  desc "creates links to maprogress for an event and its efforts"
  task :maprogress, [:event_id, :maprogress_id] => :environment do |_, args|
    event_id = args[:event_id]
    abort "No event id given" unless event_id.present?

    maprogress_id = args[:maprogress_id]
    abort "No maprogress id given" unless maprogress_id.present?

    ActiveRecord::Base.logger = nil

    begin
      event = ::Event.friendly.find(event_id)
    rescue ActiveRecord::RecordNotFound
      abort "Event not found: #{event_id}" unless event.present?
    end

    puts "Found event #{event_id}"
    print "Setting link for event..."

    base_maprogress_url = "#{maprogress_id}.maprogress.com"
    event.update(beacon_url: base_maprogress_url)

    puts "done"
    puts "Setting effort links"

    efforts = event.efforts
    efforts_count = efforts.count
    progress_bar = ::ProgressBar.new(efforts_count)

    efforts.find_each do |effort|
      progress_bar.increment!
      beacon_url = "#{base_maprogress_url}/?bib=#{effort.bib_number}&justme=yes&showpath=yes&showmarkerhistory=yes"
      effort.update(beacon_url: beacon_url)
    rescue ActiveRecordError => e
      puts "Could not set beacon url for effort #{effort.id}:"
      puts e
    end
  end
end
