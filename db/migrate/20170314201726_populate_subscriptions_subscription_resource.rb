class PopulateSubscriptionsSubscriptionResource < ActiveRecord::Migration
  def self.up
    print "Generating subscription resources for all #{Subscription.count} subscriptions in the database.\n"
    sns_client = Aws::SNS::Client.new
    Subscription.all.each do |subscription|
      subscription.resource_key = SnsSubscriptionManager.generate(subscription: subscription, sns_client: sns_client)
      subscription.save
    end
    print "\nFinished generating subscription resources.\n"
  end

  def self.down
    print "Deleting subscription resources for all #{Subscription.count} subscriptions in the database.\n"
    sns_client = Aws::SNS::Client.new
    Subscription.all.each do |subscription|
      SnsSubscriptionManager.delete(subscription: subscription, sns_client: sns_client)
    end
    print "\nFinished deleting subscription resources.\n"
  end
end
