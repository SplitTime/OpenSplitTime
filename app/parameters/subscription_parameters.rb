# frozen_string_literal: true

class SubscriptionParameters < BaseParameters

  def self.permitted
    [:id, :user_id, :subscribable_type, :subscribable_id, :protocol, :resource_key]
  end
end
