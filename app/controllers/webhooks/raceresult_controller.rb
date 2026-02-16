require 'json'

module Webhooks
  class RaceresultController < ApplicationController
    skip_before_action :verify_authenticity_token

    def receive
      raw = request.raw_post.strip
      
      # check if we have data
      return render json: { error: "No data" }, status: :bad_request if raw.blank?

      # Log the raw data      
      puts "--- RAW DATA ---"
      puts JSON.pretty_generate(JSON.parse(raw))
      data = JSON.parse(raw)      

      # extract and process the data
      processed = process_data(data)

      # Log the clean version
      puts "--- PROCESSED DATA ---"
      puts JSON.pretty_generate(processed)
      render json: { data: processed }, status: :ok

    rescue JSON::ParserError
      render json: { error: "Invalid JSON" }, status: :unprocessable_entity
    end

    private
    def process_data(input_data)
      {
        bib:          input_data["Bib"],
        utc_time:     input_data.dig("Passing", "UTCTime"),
        device_id:    input_data.dig("Passing", "DeviceID"),
        timing_point: input_data["TimingPoint"],
        id:           input_data["ID"]
      }
    end
  end
end
