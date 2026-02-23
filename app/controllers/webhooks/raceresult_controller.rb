require 'json'

module Webhooks
  class RaceresultController < ApplicationController
    skip_before_action :verify_authenticity_token

    def receive
      raw = request.raw_post.strip
      
      # Check if we have data
      return render json: { error: "No data" }, status: :bad_request if raw.blank?
      
      # Call the service to process the webhook
      result = ProcessRaceresultWebhook.new.call(raw)
      
    rescue JSON::ParserError
      render json: { error: "Invalid JSON" }, status: :unprocessable_entity
    end

    private

    def determine_error_status(error_message)
      case error_message
      when /not found/i
        :not_found
      when /required/i, /blank/i
        :bad_request
      else
        :unprocessable_entity
      end
    end
  end
end
