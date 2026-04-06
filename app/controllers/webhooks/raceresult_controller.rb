module Webhooks
  class RaceresultController < ApplicationController
    skip_before_action :verify_authenticity_token

    def receive
      Rails.logger.info("RaceResult webhook received: #{params.to_unsafe_h.except(:controller, :action)}")

      @event_group = EventGroup.friendly.find(params[:event_group_name])
      return head :unauthorized unless ActiveSupport::SecurityUtils.secure_compare(@event_group.webhook_token.to_s,
                                                                                   params[:token].to_s)
      return render json: { error: "No data" }, status: :bad_request if params[:record].blank?

      response = Interactors::Webhooks::ProcessRaceresultWebhook.call(event_group: @event_group,
                                                                      record: params[:record])

      if response.successful?
        head :created
      else
        render json: { errors: response.errors }, status: :unprocessable_content
      end
    end
  end
end
