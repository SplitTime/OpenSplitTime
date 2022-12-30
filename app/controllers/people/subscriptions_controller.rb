# frozen_string_literal: true

module People
  class SubscriptionsController < ::SubscriptionsController
    private

    def subscribable_path
      person_subscriptions_path(@subscription.subscribable)
    end

    def set_subscribable
      @subscribable = ::Person.friendly.find(params[:person_id])
    end
  end
end
