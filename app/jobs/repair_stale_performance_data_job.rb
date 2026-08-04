class RepairStalePerformanceDataJob < ApplicationJob
  queue_as :default

  def perform
    stale_event_ids = Results::EffortPerformanceDataAudit.stale_event_ids
    return if stale_event_ids.empty?

    failures = []

    stale_event_ids.each do |event_id|
      event = Event.find(event_id)
      begin
        RecomputeEffortPerformanceDataJob.perform_now([event.id])
        failures << "#{event.slug}: still stale after recompute" if event.performance_data_stale?
      rescue StandardError => e
        failures << "#{event.slug}: #{e.message}"
      end
    end

    healed_count = stale_event_ids.size - failures.size
    Rails.logger.info("RepairStalePerformanceDataJob healed #{healed_count} of #{stale_event_ids.size} stale events")

    return if failures.empty?

    report_text = <<~TEXT
      The nightly performance data repair found #{stale_event_ids.size} stale events and could not heal #{failures.size}:

      #{failures.join("\n")}
    TEXT
    AdminMailer.job_report(self.class.name, report_text).deliver_later
  end
end
