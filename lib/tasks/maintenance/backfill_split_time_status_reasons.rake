namespace :maintenance do
  desc "Backfills status_reason on flagged split_times (idempotent)"
  task backfill_split_time_status_reasons: :environment do
    puts "Re-evaluating efforts with flagged-but-reasonless split_times"

    ActiveRecord::Base.logger.silence do
      effort_ids = SplitTime
                   .where(data_status: SplitTime.data_statuses.values_at("bad", "questionable"))
                   .where(status_reason: nil)
                   .distinct.pluck(:effort_id)

      puts "Found #{effort_ids.size} efforts to re-evaluate"

      progress_bar = ::ProgressBar.new(effort_ids.size)
      split_time_changes = 0
      effort_changes = 0

      effort_ids.each do |effort_id|
        progress_bar.increment!
        effort = Effort.find(effort_id)
        response = ::Interactors::SetEffortStatus.perform(effort)

        response.resources.each do |resource|
          next unless resource.changed?

          resource.save!
          case resource
          when SplitTime then split_time_changes += 1
          when Effort then effort_changes += 1
          end
        end
      rescue ActiveRecord::ActiveRecordError => e
        puts "Could not re-evaluate effort #{effort_id}:"
        puts e
      end

      puts "Backfill complete: updated #{split_time_changes} split_times and #{effort_changes} efforts"
    end
  end
end
