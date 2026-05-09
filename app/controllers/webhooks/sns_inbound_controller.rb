require "aws-sdk-sns"

module Webhooks
  class SnsInboundController < ::ApplicationController
    skip_before_action :verify_authenticity_token

    def create
      return head :unauthorized unless valid_signature?

      case request.headers["x-amz-sns-message-type"]
      when "SubscriptionConfirmation"
        confirm_subscription
      when "Notification"
        process_notification
      when "UnsubscribeConfirmation"
        report_anomaly("unexpected SNS UnsubscribeConfirmation: #{sns_message['TopicArn']}")
        head :ok
      else
        head :bad_request
      end
    end

    private

    def valid_signature?
      return false if sns_message.nil?

      Aws::SNS::MessageVerifier.new.authentic?(request.raw_post)
    end

    def sns_message
      @sns_message ||= JSON.parse(request.raw_post)
    rescue JSON::ParserError
      nil
    end

    def confirm_subscription
      url = sns_message.fetch("SubscribeURL")
      if safe_subscribe_url?(url)
        Net::HTTP.get(URI(url))
        head :ok
      else
        report_anomaly("rejected non-AWS SubscribeURL: #{url}")
        head :bad_request
      end
    end

    def process_notification
      response = Interactors::Webhooks::ProcessSnsInboundSms.call(sns_message: sns_message)
      if response.successful?
        head :ok
      else
        render json: { errors: response.errors }, status: :unprocessable_content
      end
    end

    def safe_subscribe_url?(url)
      uri = URI.parse(url)
      uri.scheme == "https" && uri.host =~ /\Asns\.[a-z0-9-]+\.amazonaws\.com\z/
    rescue URI::InvalidURIError
      false
    end

    def report_anomaly(message)
      Rails.error.report(SmsWebhookError.new(message), handled: true)
    end
  end

  class SmsWebhookError < StandardError; end
end
