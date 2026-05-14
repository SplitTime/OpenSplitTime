namespace :maintenance do
  desc "Destroy participant subscriptions and tear down their SNS topics (idempotent)"
  task remove_person_subscriptions: :environment do
    ActiveRecord::Base.logger.silence do
      # delete_all skips Subscription#before_destroy :delete_resource_key. That callback
      # makes a live sns_client.unsubscribe round-trip per subscription, which was
      # taking ~30s+ apiece in production and would never reasonably finish for the
      # full set. The topic-deletion phase below removes the SNS topic itself, which
      # AWS responds to by auto-pruning every subscription attached to that topic
      # server-side — so the per-row unsubscribe calls were redundant anyway.
      subscription_scope = Subscription.where(subscribable_type: "Person")
      destroyed = subscription_scope.count
      puts "Deleting #{destroyed} Person subscriptions"
      subscription_scope.delete_all if destroyed.positive?

      person_scope = Person.where.not(topic_resource_key: nil)
      topics_deleted = person_scope.count
      puts "Tearing down #{topics_deleted} SNS topics"

      if topics_deleted.positive?
        topic_bar = ::ProgressBar.new(topics_deleted)
        person_scope.find_each do |person|
          SnsTopicManager.delete(resource: person)
          person.update_column(:topic_resource_key, nil)
          topic_bar.increment!
        end
      end

      puts "Done — deleted #{destroyed} Person subscriptions, tore down #{topics_deleted} SNS topics."
    end
  end
end
