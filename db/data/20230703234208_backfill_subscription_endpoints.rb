# frozen_string_literal: true

class BackfillSubscriptionEndpoints < ActiveRecord::Migration[7.0]
  def up
    Subscription.find_each do |subscription|
      user = subscription.user
      protocol = subscription.protocol
      if user && protocol
        subscription.update_columns(endpoint: user.send(protocol))
      else
        subscription.destroy!
      end
    end
  end

  def down
  end
end
