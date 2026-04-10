module Webhooks
  class MailgunEventsController < ::ApplicationController
    skip_before_action :verify_authenticity_token

    def create
      return head :unauthorized unless valid_signature?

      mailgun_event = Analytics::MailgunEvent.new(
        recipient: params[:recipient],
        timestamp: params[:timestamp],
        event: params[:event],
        mailgun_event_id: params[:id],
        mailgun_message_id: params.dig(:message, :headers, :message_id),
        ip: params[:ip],
        reason: params[:reason],
        status: params.dig(:delivery_status, :code)&.to_s,
        response: params.dig(:delivery_status, :message),
        useragent: params.dig(:client_info, :user_agent),
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
