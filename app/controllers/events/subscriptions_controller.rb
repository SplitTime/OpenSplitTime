# frozen_string_literal: true

module Events
  class SubscriptionsController < ::SubscriptionsController
    private

    def set_subscribable
      @subscribable = ::Event.friendly.find(params[:person_id])
    end
  end
end
