# frozen_string_literal: true

class SubscriptionParameters < BaseParameters

  def self.permitted
    [:id, :user_id, :person_id, :participant_id, :protocol, :resource_key]
  end
end
