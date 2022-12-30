# frozen_string_literal: true

module Efforts
  class SubscriptionsController < ::SubscriptionsController
    private

    def set_subscribable
      @subscribable = ::Effort.friendly.find(params[:effort_id])
    end
  end
end
