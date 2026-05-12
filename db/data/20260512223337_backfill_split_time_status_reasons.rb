class BackfillSplitTimeStatusReasons < ActiveRecord::Migration[8.1]
  # Populates status_reason on existing bad/questionable split_times so the
  # tooltip work from #271 has something to display on historical data.
  #
  # Only the status_reason column is persisted. data_status is intentionally
  # left untouched: re-running SetEffortStatus over old data can flip a
  # status (e.g. "bad" → "good") because the times_container has changed
  # since the original computation, and this migration is not the right
  # place to silently revise that.
  def up
    effort_ids = SplitTime
                 .where(data_status: SplitTime.data_statuses.values_at("bad", "questionable"))
                 .where(status_reason: nil)
                 .distinct.pluck(:effort_id)

    say "Backfilling status_reason across #{effort_ids.size} efforts with flagged split_times…"
    updated_count = 0

    effort_ids.each do |effort_id|
      effort = Effort.find(effort_id)
      ::Interactors::SetEffortStatus.perform(effort)

      effort.ordered_split_times.each do |split_time|
        next if split_time.status_reason.nil?

        SplitTime.where(id: split_time.id).update_all(status_reason: split_time.status_reason)
        updated_count += 1
      end
    end

    say "Backfill complete: status_reason populated on #{updated_count} split_times."
  end

  def down
    # One-way; reversing would just blank the column we just populated.
  end
end
