require 'json'

module Webhooks
  class RaceresultController < ApplicationController
    skip_before_action :verify_authenticity_token

    def receive
      raw = request.raw_post.strip
      
      # check if we have data
      return render json: { error: "No data" }, status: :bad_request if raw.blank?

      parts = raw.split(';')
      json_part = parts[0]
      event_group = parts[1]

      # Log the raw data      
      puts "--- RAW DATA ---"
      puts JSON.pretty_generate(JSON.parse(json_part))
      data = JSON.parse(json_part)      

      # extract and process the data
      processed = process_data(data)

      # Log the clean version
      puts "--- PROCESSED DATA ---"
      puts JSON.pretty_generate(processed)

      # Submit raw times
      event_group_obj = EventGroup.find_by(name: event_group)
      return render json: { error: "Event group '#{event_group}' not found" }, status: :not_found unless event_group_obj
      
      # Validate that we have time data
      elapsed_time = processed[:time]
      return render json: { error: "Elapsed time is required" }, status: :bad_request if elapsed_time.blank?
      
      # Get the first event in the group to find the start time
      first_event = event_group_obj.events.order(:scheduled_start_time).first
      return render json: { error: "No events found in event group" }, status: :bad_request unless first_event
      
      # Calculate absolute time from event start + elapsed seconds
      absolute_time = first_event.scheduled_start_time + elapsed_time.seconds
      
      # Convert elapsed seconds to HH:MM:SS format for entered_time
      hours = (elapsed_time / 3600).to_i
      minutes = ((elapsed_time % 3600) / 60).to_i
      seconds = (elapsed_time % 60).to_i
      entered_time = sprintf("%02d:%02d:%02d", hours, minutes, seconds)
      
      raw_time = RawTime.new(
        event_group: event_group_obj,
        bib_number: processed[:bib],
        split_name: processed[:timing_point],
        absolute_time: absolute_time,
        entered_time: entered_time,
        bitkey: SubSplit::IN_BITKEY,
        source: "raceresult_webhook",
        created_by: nil  # Webhook submission has no user
      )
      
      begin
        raw_time.save!
      rescue ActiveRecord::RecordInvalid => e
        error_messages = raw_time.errors.full_messages.join(", ")
        puts "--- SAVE ERROR ---"
        puts "Error: #{error_messages}"
        puts "All errors: #{raw_time.errors.messages}"
        return render json: { error: "Failed to save raw time: #{error_messages}" }, status: :unprocessable_entity
      end
      
      raw_time_rows = RowifyRawTimes.build(event_group: event_group_obj, raw_times: [raw_time])
      
      response = Interactors::SubmitRawTimeRows.perform!(
        raw_time_rows: raw_time_rows,
        event_group: event_group_obj,
        force_submit: false,
        mark_as_reviewed: false,
        current_user_id: nil
      )

      # Check if submission was successful
      if response.errors.present?
        render json: { data: processed, errors: response.errors }, status: :unprocessable_entity
      else
        render json: { success: true, message: "Raw time submitted successfully", data: processed, raw_time_id: raw_time.id }, status: :ok
      end

    rescue JSON::ParserError
      render json: { error: "Invalid JSON" }, status: :unprocessable_entity
    end

    private
    def process_data(input_data)
      {
        bib:          input_data["Bib"],
        time:         input_data["Time"],  # Elapsed time in seconds
        device_id:    input_data.dig("Passing", "DeviceID"),
        timing_point: input_data["TimingPoint"],
        id:           input_data["ID"]
      }
    end


  end
end
