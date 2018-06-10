namespace :convert do
  desc 'Convert all live_times to raw_times'
  task :live_to_raw_times => :environment do
    start_time = Time.current

    puts "Converting #{LiveTime.count} live_times to raw_times"

    IDENTICAL_ATTRIBUTES = %i[bitkey bib_number absolute_time entered_time with_pacer stopped_here source pulled_by pulled_at created_by updated_by remarks]

    ActiveRecord::Base.transaction do
      LiveTime.includes(:event, :split).find_each.with_index(1) do |live_time, i|
        raw_time = RawTime.new(event_group_id: live_time.event.event_group_id,
                               split_time_id: live_time.split_time_id,
                               split_name: live_time.split.base_name)
        IDENTICAL_ATTRIBUTES.each { |attr| raw_time[attr] = live_time.send(attr) }

        unless raw_time.save
          abort "Could not convert #{live_time}: #{raw_time.errors.full_messages}"
        end

        p "Converted #{i} records\n" if (i % 100 == 0) || i == LiveTime.count
      end
    end

    elapsed_time = Time.current - start_time
    puts "\nFinished conversion in #{elapsed_time} seconds"
  end
end
