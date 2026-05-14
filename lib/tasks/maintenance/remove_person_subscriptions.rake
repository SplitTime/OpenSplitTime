namespace :maintenance do
  desc "Destroy participant subscriptions and tear down their SNS topics (idempotent)"
  task remove_person_subscriptions: :environment do
    # Destroy per-user subscriptions first so Subscription#before_destroy can call
    # SnsSubscriptionManager.delete cleanly. If we deleted the topic first, AWS
    # auto-removes the subscription ARNs and the per-subscription cleanup would
    # have nothing to address.
    destroyed = 0
    Subscription.where(subscribable_type: "Person").find_each do |subscription|
      subscription.destroy!
      destroyed += 1
    end

    topics_deleted = 0
    Person.where.not(topic_resource_key: nil).find_each do |person|
      SnsTopicManager.delete(resource: person)
      person.update_column(:topic_resource_key, nil)
      topics_deleted += 1
    end

    puts "Destroyed #{destroyed} Person subscriptions, tore down #{topics_deleted} SNS topics."
  end
end
