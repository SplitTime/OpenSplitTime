require 'json'

module Webhooks
  class RaceresultController < ApplicationController
    skip_before_action :verify_authenticity_token

    def receive
      raw = request.raw_post.strip
      Rails.logger.debug("[RaceresultWebhook] raw=#{raw}")
      return render json: { error: "No data" }, status: :bad_request if raw.blank?

      response = Interactors::Webhooks::ProcessRaceresultWebhook.call(raw)

      if response.successful?
        head :created
      else
        render json: { errors: response.errors }, status: :unprocessable_entity
      end
    rescue JSON::ParserError
      render json: { error: "Invalid JSON" }, status: :unprocessable_entity
    end
  end
end
