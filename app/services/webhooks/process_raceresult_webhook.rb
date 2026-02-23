class ProcessRaceresultWebhook
  def call(raw)
    # The raw data is expected to be in the format: JSON_DATA;EVENT_GROUP_NAME
    json, event_group_name = self.class.parse_raw(raw)
    processed = self.class.process_data(JSON.parse(json))
    
    Rails.logger.info "Processing webhook - Bib: #{processed[:bib]}, Time: #{processed[:time]}, TimingPoint: #{processed[:timing_point]}"
    
    event_group_obj = find_event_group(event_group_name)
    return event_group_obj if event_group_obj.is_a?(Hash) && event_group_obj[:error]
    
    raw_time = build_raw_time(event_group_obj, processed)
    return raw_time if raw_time.is_a?(Hash) && raw_time[:error]
    
    save_result = save_raw_time(raw_time)
    return save_result if save_result.is_a?(Hash) && save_result[:error]
    
    Rails.logger.info "Raw time saved successfully (ID: #{raw_time.id})"
    
    result = submit_raw_time(event_group_obj, raw_time, processed)
    Rails.logger.info "Submission result: #{result[:message] || result[:errors]}"
    
    result
  end

  private

  def find_event_group(event_group_name)
    event_group = EventGroup.find_by(name: event_group_name)
    return { error: "Event group '#{event_group_name}' not found" } unless event_group
    
    event_group
  end

  def build_raw_time(event_group, processed)
    elapsed_time = processed[:time].to_i
    return { error: "Elapsed time is required" } if elapsed_time.blank? || elapsed_time.zero?
    
    absolute_time = calculate_absolute_time(event_group, elapsed_time)
    return absolute_time if absolute_time.is_a?(Hash) && absolute_time[:error]
    
    entered_time = format_elapsed_time(elapsed_time)
    
    RawTime.new(
      event_group: event_group,
      bib_number: processed[:bib],
      split_name: processed[:timing_point],
      absolute_time: absolute_time,
      entered_time: entered_time,
      bitkey: SubSplit::IN_BITKEY,
      source: "raceresult_webhook",
      created_by: nil
    )
  end

  def calculate_absolute_time(event_group, elapsed_time)
    first_event = event_group.events.order(:scheduled_start_time).first
    return { error: "No events found in event group" } unless first_event
    
    first_event.scheduled_start_time + elapsed_time.seconds
  end

  def format_elapsed_time(elapsed_time)
    hours = (elapsed_time / 3600).to_i
    minutes = ((elapsed_time % 3600) / 60).to_i
    seconds = (elapsed_time % 60).to_i
    sprintf("%02d:%02d:%02d", hours, minutes, seconds)
  end

  def save_raw_time(raw_time)
    raw_time.save!
    raw_time
  rescue ActiveRecord::RecordInvalid => e
    error_messages = raw_time.errors.full_messages.join(", ")
    Rails.logger.error "Failed to save raw time: #{error_messages}"
    { error: "Failed to save raw time: #{error_messages}" }
  end

  def submit_raw_time(event_group, raw_time, processed)
    raw_time_rows = RowifyRawTimes.build(event_group: event_group, raw_times: [raw_time])

    response = Interactors::SubmitRawTimeRows.perform!(
      raw_time_rows: raw_time_rows,
      event_group: event_group,
      force_submit: false,
      mark_as_reviewed: false,
      current_user_id: nil
    )

    if response.errors.present?
      Rails.logger.error "Interactor errors: #{response.errors}"
      { data: processed, errors: response.errors }
    else
      { data: processed, message: "Raw time submitted successfully", raw_time_id: raw_time.id }
    end
  end

  def self.parse_raw(raw)
    parts = raw.split(';')
    json = parts[0]
    event_group = parts[1]

    # Log the raw data
    Rails.logger.info "Parsed JSON: #{json}"
    Rails.logger.info "Parsed Event Group: #{event_group}"

    return json, event_group
  end

  def self.process_data(input_data)
    {
      bib:          input_data["Bib"],
      time:         input_data["Time"],  # Elapsed time in seconds
      device_id:    input_data.dig("Passing", "DeviceID"),
      timing_point: input_data["TimingPoint"],
      id:           input_data["ID"]
    }
  end
end