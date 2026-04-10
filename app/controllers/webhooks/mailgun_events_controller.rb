module Webhooks
  class MailgunEventsController < ::ApplicationController
    skip_before_action :verify_authenticity_token

    def create
      return head :unauthorized unless valid_signature?

      event_data = params.require(:event_data)
      mailgun_event = Analytics::MailgunEvent.new(
        recipient: event_data[:recipient],
        timestamp: event_data[:timestamp],
        event: event_data[:event],
        mailgun_event_id: event_data[:id],
        mailgun_message_id: event_data.dig(:message, :headers, :message_id),
        ip: event_data[:ip],
        reason: event_data[:reason],
        status: event_data.dig(:delivery_status, :code)&.to_s,
        response: event_data.dig(:delivery_status, :message),
        useragent: event_data.dig(:client_info, :user_agent),
      )

      if mailgun_event.save
        head :ok
      else
        head :unprocessable_content
      end
    rescue ActionController::ParameterMissing
      head :unprocessable_content
    end

    private

    def valid_signature?
      signature_data = params.require(:signature)
      timestamp = signature_data[:timestamp]
      token = signature_data[:token]
      signature = signature_data[:signature]

      digest = OpenSSL::HMAC.hexdigest("SHA256", OstConfig.mailgun_webhook_signing_key, "#{timestamp}#{token}")
      ActiveSupport::SecurityUtils.secure_compare(digest, signature)
    end
  end
end
