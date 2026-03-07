require 'json'

module Webhooks
  class RaceresultController < ApplicationController
    skip_before_action :verify_authenticity_token

    def receive
      raw = request.raw_post.strip
      Rails.logger.debug("[RaceresultWebhook] raw=#{raw}")
      return render json: { error: "No data" }, status: :bad_request if raw.blank?
      
      Interactors::Webhooks::ProcessRaceresultWebhook.call(raw)
      head :created
    rescue JSON::ParserError
      render json: { error: "Invalid JSON" }, status: :unprocessable_entity
    rescue ActiveRecord::RecordNotFound
      render json: { error: "Event group not found" }, status: :unprocessable_entity
    rescue ArgumentError => e
      render json: { error: e.message }, status: :unprocessable_entity
    end
  end
end