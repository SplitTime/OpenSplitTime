class SweepSubscriptionsJob < ApplicationJob
  queue_as :default

  def perform
    start_time = Time.current
    report = ""
    report += "Started job for #{OstConfig.app_name} at #{start_time}\n"

    problem_subs = []
    obsolete_effort_ids = Effort.joins(:event).where(events: { scheduled_start_time: ...1.year.ago }).select(:id)
    obsolete_subs = Subscription.where(subscribable_type: "Effort", subscribable_id: obsolete_effort_ids)

    count = obsolete_subs.count
    if count.zero?
      report += "No obsolete subscriptions found\n"
    else
      report += "Found #{count} obsolete subscription(s)\n"

      obsolete_subs.find_in_batches do |subs|
        subs.each do |sub|
          problem_subs << sub.id unless sub.destroy
        end
      end

      report += if problem_subs.present?
                  "Could not destroy the following #{problem_subs.size} subscriptions: #{problem_subs.join(', ')}\n"
                else
                  "Destroyed all #{count} obsolete subscription(s)\n"
                end
    end

    duration = (Time.current - start_time).round(1)
    report += "Finished job in #{duration} seconds at #{Time.current}\n"

    AdminMailer.job_report(self.class, report).deliver_now
  end
end
