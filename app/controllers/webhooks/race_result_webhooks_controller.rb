class Webhooks::RaceResultWebhooksController < ::ApplicationController
  skip_before_action :verify_authenticity_token #, if: :valid_webhook_token?

  def create
    status = :ok
    response_body= nil

    payload = extract_webhook_params
    raw_time= build_raw_time_from_payload(payload)

    if raw_time.save
      Rails.logger.info("RaceResult webhook received, RawTime Created: #{raw_time.id}"\
      "Event_group_id=#{raw_time.event_group_id}, bib=#{raw_time.bib_number}, " \
        "split=#{raw_time.split_name}, bitkey=#{raw_time.bitkey})"
        )
      response_body = {
        status:      'success',
        message:     'Webhook received successfully',
        raw_time_id: raw_time.id,
        received_at: Time.current.iso8601
      }

    else
      Rails.logger.warn(
        "[RaceResultWebhook] Failed to create RawTime: #{raw_time.errors.full_messages.join(', ')}")

      status        = :unprocessable_entity
      response_body = {
        status:  'error',
        message: 'Failed to create raw time',
        errors:  raw_time.errors.full_messages
      }
    end

    
    render json: response_body, status: status
  rescue JSON::ParserError => e
    Rails.logger.error("Error parsing RaceResult webhook JSON: #{e.message}")

    render json: {
      status:  'error',
      message: 'Invalid JSON',
      error:   e.message
    }, status: :bad_request
  rescue StandardError => e
    Rails.logger.error("Error processing RaceResult webhook: #{e.message}")
    Rails.logger.error(e.backtrace.join("\n"))

    render json: {
      status:  'error',
      message: 'Internal server error',
      error:   e.message
    }, status: :internal_server_error
  end

  # GET /status 
  def status
    render json: {
      status:    'operational',
      service:   'RaceResult Webhook Receiver',
      version:   '1.0.0',
      timestamp: Time.current.iso8601
    }
  end

  private

  def raceresult_event_params
    [
      :event_group_id,
      :raw_data,
      :participant,
      :source_ip,
      :user_agent
    ]
  end

  def extract_webhook_params
    raw_body = request.body.read
    request.body.rewind

    parsed_payload =
      if raw_body.present?
        JSON.parse(raw_body).with_indifferent_access
      else
        {}
      end

    parsed_payload.merge(
      source_ip: request.remote_ip,
      user_agent: request.user_agent
    )
  rescue JSON::ParserError => e
    Rails.logger.error("Failed to parse webhook JSON: #{e.message}")
    webhook_params_with_metadata
  end

  def webhook_params_with_metadata
    permitted = params.except(:controller, :action, :format).permit!.to_h

    permitted.merge(
      source_ip:  request.remote_ip,
      user_agent: request.user_agent
    ).with_indifferent_access
  end

  def build_raw_time_from_payload(payload)
    raw_data    = payload[:raw_data]    || {}
    participant = payload[:participant] || {}

    event_group_id = payload[:event_group_id] || params[:event_group_id]
    event_group    = EventGroup.find_by(id: event_group_id)

    absolute_time = parse_absolute_time(raw_data[:absolute_time])

    RawTime.new(
      event_group:   event_group,
      bib_number:    participant[:bib_number] || raw_data[:bib_number],
      split_name:    raw_data[:split_name] || 'RaceResult',
      bitkey:        (raw_data[:bitkey] || 1), 
      lap:           (raw_data[:lap] || 1),

      # RawTime validations require entered_time, split_name, bitkey, bib_number, source, event_group
      entered_time:  absolute_time&.strftime('%H:%M:%S'),
      absolute_time: absolute_time,
      source:        'raceresult_webhook'
    )
  end

  def parse_absolute_time(value)
    return nil if value.blank?

    Time.parse(value)
  rescue ArgumentError
    nil
  end
end
