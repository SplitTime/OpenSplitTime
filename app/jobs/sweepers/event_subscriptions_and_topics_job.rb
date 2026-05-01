module Sweepers
  class EventSubscriptionsAndTopicsJob < ApplicationJob
    queue_as :default

    SUBSCRIPTION_AGE_CUTOFF = 3.months
    TOPIC_AGE_CUTOFF = 30.days

    def perform(dry_run: false)
      @dry_run = dry_run
      @start_time = Time.current
      @report = +""
      banner = "Started Sweepers::EventSubscriptionsAndTopicsJob for #{OstConfig.app_name} at #{@start_time}"
      banner += " (DRY RUN — no deletions will be performed)" if dry_run
      append(banner)

      sweep_stale_event_subscriptions
      sweep_topics_on_stale_events

      append("Finished job in #{(Time.current - @start_time).round(1)} seconds at #{Time.current}")
      AdminMailer.job_report(self.class, @report).deliver_now
    end

    private

    attr_reader :dry_run

    def sweep_stale_event_subscriptions
      append("\n[Pass 1] Sweeping stale Event subscriptions")

      stale_event_ids = Event.where("events.scheduled_start_time < ?", SUBSCRIPTION_AGE_CUTOFF.ago).select(:id)
      obsolete_subs = Subscription.where(subscribable_type: "Event", subscribable_id: stale_event_ids)
      count = obsolete_subs.count

      if count.zero?
        append("  No stale Event subscriptions found")
        return
      end

      append("  Found #{count} stale Event subscription(s)")
      return append("  DRY RUN — skipping destruction") if dry_run

      problem_ids = []
      obsolete_subs.find_in_batches do |batch|
        batch.each { |sub| problem_ids << sub.id unless sub.destroy }
      end

      if problem_ids.present?
        append("  Could not destroy #{problem_ids.size} subscription(s): #{problem_ids.join(', ')}")
      else
        append("  Destroyed all #{count} stale Event subscription(s)")
      end
    end

    def sweep_topics_on_stale_events
      append("\n[Pass 2] Sweeping topics on stale Events")

      candidates = Event.having_topic_resource_key
                        .where("events.scheduled_start_time < ?", TOPIC_AGE_CUTOFF.ago)

      total_candidates = candidates.count
      append("  #{total_candidates} candidate Event(s) past the #{TOPIC_AGE_CUTOFF.inspect} cutoff")
      return if total_candidates.zero?

      deleted_count = 0
      skipped_with_subs = 0
      problem_ids = []

      candidates.find_each do |event|
        if event.subscriptions.exists?
          skipped_with_subs += 1
          next
        end

        if dry_run
          append("  [dry-run] would delete topic for Event##{event.id} (#{event.topic_resource_key})")
          next
        end

        if delete_topic_for(event)
          deleted_count += 1
        else
          problem_ids << event.id
        end
      end

      if skipped_with_subs.positive?
        append("  Skipped #{skipped_with_subs} Event(s) that still had subscriptions after Pass 1")
      end
      append("  Deleted #{deleted_count} topic(s)")
      append("  Failed on #{problem_ids.size} Event(s): #{problem_ids.join(', ')}") if problem_ids.present?
    end

    def delete_topic_for(event)
      event.unassign_topic_resource
      event.save!
      true
    rescue SnsTopicManager::TopicNotDeletedError,
           Aws::SNS::Errors::ServiceError,
           ActiveRecord::RecordInvalid => e
      Rails.logger.warn("  Topic delete failed for Event##{event.id}: #{e.class.name}: #{e.message}")
      false
    end

    def append(line)
      @report << line << "\n"
      Rails.logger.info(line)
    end
  end
end
