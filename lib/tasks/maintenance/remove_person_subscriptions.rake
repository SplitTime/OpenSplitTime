namespace :maintenance do
  desc "Destroy participant subscriptions and tear down their SNS topics (idempotent)"
  task remove_person_subscriptions: :environment do
    ActiveRecord::Base.logger.silence do
      # Destroy per-user subscriptions first so Subscription#before_destroy can call
      # SnsSubscriptionManager.delete cleanly. If we deleted the topic first, AWS
      # auto-removes the subscription ARNs and the per-subscription cleanup would
      # have nothing to address.
      subscription_scope = Subscription.where(subscribable_type: "Person")
      destroyed = subscription_scope.count
      puts "Destroying #{destroyed} Person subscriptions"

      if destroyed.positive?
        subscription_bar = ::ProgressBar.new(destroyed)
        subscription_scope.find_each do |subscription|
          subscription.destroy!
          subscription_bar.increment!
        end
      end

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

      puts "Done — destroyed #{destroyed} Person subscriptions, tore down #{topics_deleted} SNS topics."
    end
  end
end
