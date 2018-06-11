namespace :convert do
  desc 'Convert all live_times to raw_times'
  task :live_to_raw_times => :environment do
    start_time = Time.current

    puts "Converting #{LiveTime.count} live_times to raw_times"

    ActiveRecord::Base.transaction do
      LiveTime.includes(:event, :split).find_each.with_index(1) do |live_time, i|
        raw_time = RawTimeFromLiveTime.build(live_time)

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
