# frozen_string_literal: true

# Location: app/controllers/webhooks/race_result_webhooks_controller.rb
# Endpoints:
#   POST /webhooks/race_result_webhooks         -> create
#   GET  /webhooks/race_result_webhooks/status  -> status

class Webhooks::RaceResultWebhooksController < ::ApplicationController
  # Webhooks are POSTed by an external system; disable CSRF for this controller.
  skip_before_action :verify_authenticity_token

  # POST /webhooks/race_result_webhooks
  def create
    webhook_params = extract_webhook_params

    # Persist/log the webhook (model method you already implemented)
    webhook = RaceResultWebhook.log_webhook(webhook_params)

    if webhook
      # If/when you add async processing:
      # RaceResult::WebhookProcessorJob.perform_later(webhook.id)

      Rails.logger.info("RaceResult webhook received: #{webhook.id}")
      Rails.logger.info(
        "Webhook details: Event ID: #{webhook.event_id}, " \
        "Trigger: #{webhook.trigger_type}, " \
        "Timestamp: #{webhook.webhook_timestamp}"
      )

      render json: {
        status: 'success',
        message: 'Webhook received successfully',
        webhook_id: webhook.id,
        received_at: Time.current.iso8601
      }, status: :ok
    else
      render json: {
        status: 'error',
        message: 'Failed to log webhook data'
      }, status: :unprocessable_entity
    end
  rescue StandardError => e
    Rails.logger.error("Error processing RaceResult webhook: #{e.message}")
    Rails.logger.error(e.backtrace.join("\n"))

    render json: {
      status: 'error',
      message: 'Internal server error',
      error: e.message
    }, status: :internal_server_error
  end

  # GET /webhooks/race_result_webhooks/status
  # Lightweight health check for the receiver
  def status
    render json: {
      status: 'operational',
      service: 'RaceResult Webhook Receiver',
      version: '1.0.0',
      timestamp: Time.current.iso8601
    }
  end

  private

  # Prefer raw-body JSON; fall back to strong-params if body isn't JSON.
  def extract_webhook_params
    raw_body = request.body.read
    request.body.rewind

    parsed_payload =
      if raw_body.present?
        JSON.parse(raw_body).with_indifferent_access
      else
        {}
      end

    # Attach request metadata
    parsed_payload.merge(
      source_ip: request.remote_ip,
      user_agent: request.user_agent
    )
  rescue JSON::ParserError => e
    Rails.logger.error("Failed to parse webhook JSON: #{e.message}")
    webhook_params_with_metadata
  end

  # Fallback for form-encoded or non-JSON posts
  def webhook_params_with_metadata
    # Permit everything at the boundary; downstream model should validate/shape.
    permitted = params.except(:controller, :action, :format).permit!.to_h
    permitted.merge(
      source_ip: request.remote_ip,
      user_agent: request.user_agent
    )
  end
end
