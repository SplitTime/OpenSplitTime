# frozen_string_literal: true

class SweepSubscriptionsJob < ApplicationJob
  queue_as :default

  def perform
    start_time = Time.current
    report = ''
    report += "Started job for #{ENV['HEROKU_APP_NAME']} at #{start_time}\n"

    problem_subs = []
    obsolete_subs = Subscription.joins('join efforts on efforts.id = subscriptions.subscribable_id join events on events.id = efforts.event_id')
                      .where("subscriptions.subscribable_type = 'Effort' and events.scheduled_start_time < ?", 1.year.ago)

    count = obsolete_subs.count
    if count == 0
      report += "No obsolete subscriptions found\n"
    else
      report += "Found #{count} obsolete subscription(s)\n"

      obsolete_subs.find_in_batches do |subs|
        subs.each do |sub|
          problem_subs << sub.id unless sub.destroy
        end
      end

      if problem_subs.present?
        report += "Could not destroy the following #{problem_subs.size} subscriptions: #{problem_subs.join(', ')}\n"
      else
        report += "Destroyed all #{count} obsolete subscription(s)\n"
      end
    end

    duration = (Time.current - start_time).round(1)
    report += "Finished job in #{duration} seconds at #{Time.current}\n"

    AdminMailer.job_report(self.class, report).deliver_now
  end
end
