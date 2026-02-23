require 'json'

module Webhooks
  class RaceresultController < ApplicationController
    skip_before_action :verify_authenticity_token

    def receive
      raw = request.raw_post.strip
      return render json: { error: "No data" }, status: :bad_request if raw.blank?
      
      Interactors::Webhooks::ProcessRaceresultWebhook.call(raw)
      head :created
    rescue JSON::ParserError
      render json: { error: "Invalid JSON" }, status: :unprocessable_entity
    rescue ActiveRecordError::NotFoundError
      render json: { error: "Event group not found" }, status: :unprocessable_entity
    end
  end
end
