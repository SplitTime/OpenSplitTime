class RepairStalePerformanceDataJob < ApplicationJob
  queue_as :default

  # Reports by email on every run for now; switch to failure-only
  # reporting once the job has a track record
  def perform
    healed = []
    failures = []

    Results::EffortPerformanceDataAudit.stale_event_ids.each do |event_id|
      event = Event.find(event_id)
      begin
        RecomputeEffortPerformanceDataJob.perform_now([event.id])
        if event.performance_data_stale?
          failures << "#{event.slug}: still stale after recompute"
        else
          healed << event.slug
        end
      rescue StandardError => e
        failures << "#{event.slug}: #{e.message}"
      end
    end

    total = healed.size + failures.size
    Rails.logger.info("RepairStalePerformanceDataJob healed #{healed.size} of #{total} stale events")
    AdminMailer.job_report(self.class.name, report_text(healed, failures)).deliver_later
  end

  private

  def report_text(healed, failures)
    return "The performance data repair job found no stale events." if healed.empty? && failures.empty?

    <<~TEXT
      The performance data repair job found #{healed.size + failures.size} stale events.

      Healed:
      #{healed.presence&.join("\n") || '(none)'}

      Failed:
      #{failures.presence&.join("\n") || '(none)'}
    TEXT
  end
end
