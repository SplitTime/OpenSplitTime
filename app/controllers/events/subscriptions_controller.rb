module Events
  class SubscriptionsController < ::SubscriptionsController
    private

    def set_subscribable
      @subscribable = ::Event.friendly.find(params[:event_id])
    end
  end
end
