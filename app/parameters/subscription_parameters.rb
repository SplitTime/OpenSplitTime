class SubscriptionParameters < BaseParameters

  def self.permitted
    [:id, :user_id, :participant_id, :protocol, :resource_key]
  end
end
