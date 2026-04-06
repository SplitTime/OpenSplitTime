module Webhooks
  class RaceresultController < ApplicationController
    skip_before_action :verify_authenticity_token

    def receive
      payload = JSON.parse(request.raw_post)
      Rails.logger.info("RaceResult webhook received: #{payload}")

      @event_group = EventGroup.friendly.find(payload["event_group_name"])
      return head :unauthorized unless ActiveSupport::SecurityUtils.secure_compare(
        @event_group.webhook_token.to_s, params[:token].to_s
      )

      record = payload["record"]
      return render json: { error: "No data" }, status: :bad_request if record.blank?

      response = Interactors::Webhooks::ProcessRaceresultWebhook.call(
        event_group: @event_group, record: record
      )

      if response.successful?
        head :created
      else
        render json: { errors: response.errors }, status: :unprocessable_content
      end
    rescue JSON::ParserError
      render json: { error: "Invalid JSON" }, status: :unprocessable_content
    end
  end
end
