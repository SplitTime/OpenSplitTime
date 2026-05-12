class BackfillSplitTimeStatusReasons < ActiveRecord::Migration[8.1]
  # Re-runs SetEffortStatus over efforts with any flagged-but-reasonless
  # split_time, then saves the recompute. status_reason gets populated, and
  # data_status is brought in line with the current calculation (which may
  # flip some historical "bad"/"questionable" entries to "good" if the
  # times_container baseline has shifted in the participant's favor).
  def up
    effort_ids = SplitTime
                 .where(data_status: SplitTime.data_statuses.values_at("bad", "questionable"))
                 .where(status_reason: nil)
                 .distinct.pluck(:effort_id)

    say "Re-evaluating status across #{effort_ids.size} efforts with flagged split_times…"
    split_time_changes = 0
    effort_changes = 0

    effort_ids.each do |effort_id|
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
    end

    say "Backfill complete: updated #{split_time_changes} split_times and #{effort_changes} efforts."
  end

  def down
    # One-way; reversing would require remembering the old data_status /
    # status_reason values prior to the recompute.
  end
end
