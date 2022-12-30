# frozen_string_literal: true

module Efforts
  class SubscriptionsController < ::SubscriptionsController
    private

    def subscribable_path
      effort_subscriptions_path(@subscription.subscribable)
    end

    def set_subscribable
      @subscribable = ::Effort.friendly.find(params[:effort_id])
    end
  end
end
