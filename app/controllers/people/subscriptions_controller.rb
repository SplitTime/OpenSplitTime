module People
  class SubscriptionsController < ::SubscriptionsController
    private

    def set_subscribable
      @subscribable = ::Person.friendly.find(params[:person_id])
    end
  end
end
