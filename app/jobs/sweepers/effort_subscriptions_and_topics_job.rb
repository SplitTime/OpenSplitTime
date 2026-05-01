module Sweepers
  class EffortSubscriptionsAndTopicsJob < ApplicationJob
    queue_as :default

    SUBSCRIPTION_FINISHED_CUTOFF = 10.days
    SUBSCRIPTION_ABSOLUTE_CUTOFF = 3.months
    TOPIC_AGE_CUTOFF = 30.days
    ORPHANED_DRIFT_THRESHOLD = 100

    class OrphanedTopicDriftError < StandardError; end

    def perform(dry_run: false)
      @dry_run = dry_run
      @start_time = Time.current
      @report = +""
      @orphaned_arns = []
      banner = "Started Sweepers::EffortSubscriptionsAndTopicsJob for #{OstConfig.app_name} at #{@start_time}"
      banner += " (DRY RUN — no deletions will be performed)" if dry_run
      append(banner)

      sweep_stale_effort_subscriptions
      sweep_topics_on_stale_efforts
      sweep_orphaned_aws_topics
      append("Finished job in #{(Time.current - @start_time).round(1)} seconds at #{Time.current}")
      AdminMailer.job_report(self.class, @report).deliver_now

      raise_on_orphaned_drift
    end

    private

    attr_reader :dry_run

    def sweep_stale_effort_subscriptions
      append("\n[Pass 1] Sweeping stale Effort subscriptions")

      stale_effort_ids = stale_effort_ids_for_subscription_sweep
      obsolete_subs = Subscription.where(subscribable_type: "Effort", subscribable_id: stale_effort_ids)
      count = obsolete_subs.count

      if count.zero?
        append("  No stale Effort subscriptions found")
        return
      end

      append("  Found #{count} stale Effort subscription(s)")
      return append("  DRY RUN — skipping destruction") if dry_run

      problem_ids = []
      obsolete_subs.find_in_batches do |batch|
        batch.each { |sub| problem_ids << sub.id unless sub.destroy }
      end

      if problem_ids.present?
        append("  Could not destroy #{problem_ids.size} subscription(s): #{problem_ids.join(', ')}")
      else
        append("  Destroyed all #{count} stale Effort subscription(s)")
      end
    end

    def sweep_topics_on_stale_efforts
      append("\n[Pass 2] Sweeping topics on stale finished Efforts")

      candidates = Effort.joins(:event)
                         .having_topic_resource_key
                         .where(finished: true)
                         .where(
                           "COALESCE(efforts.scheduled_start_time, events.scheduled_start_time) < ?",
                           TOPIC_AGE_CUTOFF.ago,
                         )

      total_candidates = candidates.count
      append("  #{total_candidates} candidate Effort(s) past the #{TOPIC_AGE_CUTOFF.inspect} cutoff")
      return if total_candidates.zero?

      deleted_count = 0
      skipped_with_subs = 0
      problem_ids = []

      candidates.find_each do |effort|
        if effort.subscriptions.exists?
          skipped_with_subs += 1
          next
        end

        if dry_run
          append("  [dry-run] would delete topic for Effort##{effort.id} (#{effort.topic_resource_key})")
          next
        end

        if delete_topic_for(effort)
          deleted_count += 1
        else
          problem_ids << effort.id
        end
      end

      if skipped_with_subs.positive?
        append("  Skipped #{skipped_with_subs} Effort(s) that still had subscriptions after Pass 1")
      end
      append("  Deleted #{deleted_count} topic(s)")
      append("  Failed on #{problem_ids.size} Effort(s): #{problem_ids.join(', ')}") if problem_ids.present?
    end

    def sweep_orphaned_aws_topics
      append("\n[Pass 3] Sweeping orphaned AWS topics (defense-in-depth)")

      ost_arns = list_ost_topic_arns
      append("  Found #{ost_arns.size} OST-namespace topic(s) in AWS")

      live_keys = collect_live_topic_resource_keys
      append("  Found #{live_keys.size} live topic_resource_key(s) in DB")

      @orphaned_arns = ost_arns - live_keys
      append("  Identified #{@orphaned_arns.size} orphaned topic(s)")
      return if @orphaned_arns.empty?

      return append("  DRY RUN — skipping orphaned-topic deletions") if dry_run

      deleted_count = 0
      problem_arns = []
      live_keys_set = live_keys.to_set

      @orphaned_arns.each do |arn|
        # Re-check the DB right before deleting in case a new resource grabbed this ARN
        # between listing and deleting (concurrent-creation race).
        next if live_keys_set.include?(arn) || any_topic_resource_key_exists?(arn)

        begin
          SnsClientFactory.client.delete_topic(topic_arn: arn)
          deleted_count += 1
        rescue Aws::SNS::Errors::ServiceError => e
          problem_arns << "#{arn} (#{e.class.name.demodulize})"
        end
      end

      append("  Deleted #{deleted_count} orphaned topic(s)")
      append("  Failed on #{problem_arns.size}: #{problem_arns.join(', ')}") if problem_arns.present?
    end

    def stale_effort_ids_for_subscription_sweep
      Effort.joins(:event).where(
        "(efforts.finished = TRUE AND " \
        "COALESCE(efforts.scheduled_start_time, events.scheduled_start_time) < ?) " \
        "OR COALESCE(efforts.scheduled_start_time, events.scheduled_start_time) < ?",
        SUBSCRIPTION_FINISHED_CUTOFF.ago,
        SUBSCRIPTION_ABSOLUTE_CUTOFF.ago,
      ).select(:id)
    end

    def delete_topic_for(effort)
      effort.unassign_topic_resource
      effort.save!
      true
    rescue SnsTopicManager::TopicNotDeletedError,
           Aws::SNS::Errors::ServiceError,
           ActiveRecord::RecordInvalid => e
      Rails.logger.warn("  Topic delete failed for Effort##{effort.id}: #{e.class.name}: #{e.message}")
      false
    end

    def list_ost_topic_arns
      arns = []
      next_token = nil
      pattern = ost_topic_name_pattern

      loop do
        response = SnsClientFactory.client.list_topics(next_token: next_token)
        response.topics.each do |topic|
          arns << topic.topic_arn if topic.topic_arn.split(":").last&.match?(pattern)
        end
        next_token = response.next_token
        break if next_token.blank?
      end

      arns
    end

    def collect_live_topic_resource_keys
      [Effort, Event, Person].flat_map do |klass|
        klass.where.not(topic_resource_key: nil).pluck(:topic_resource_key)
      end.compact
    end

    def any_topic_resource_key_exists?(arn)
      [Effort, Event, Person].any? { |klass| klass.exists?(topic_resource_key: arn) }
    end

    def ost_topic_name_pattern
      prefix = Rails.env.production? ? "" : "#{Rails.env.first}-"
      /\A#{Regexp.escape(prefix)}follow-/
    end

    def raise_on_orphaned_drift
      return if @orphaned_arns.size <= ORPHANED_DRIFT_THRESHOLD

      raise OrphanedTopicDriftError,
            "Found #{@orphaned_arns.size} orphaned AWS topics, exceeding threshold of #{ORPHANED_DRIFT_THRESHOLD}. " \
            "The Subscribable lifecycle may be dropping deletes."
    end

    def append(line)
      @report << line << "\n"
      Rails.logger.info(line)
    end
  end
end
