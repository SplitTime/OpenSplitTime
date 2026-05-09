module Interactors
  module Webhooks
    class ProcessSnsInboundSms
      include Interactors::Errors

      KEYWORDS = %w[STOP START HELP].freeze

      def self.call(sns_message:)
        new(sns_message: sns_message).call
      end

      def initialize(sns_message:)
        @sns_message = sns_message
        @errors = []
      end

      def call
        find_or_create_record
        apply_state_change if record.previously_new_record?
        Interactors::Response.new(errors, "", [record])
      rescue KeyError, JSON::ParserError => e
        Rails.error.report(e, handled: true, context: { sns_message_id: sns_message["MessageId"] })
        errors << sns_payload_error(e.message)
        Interactors::Response.new(errors, "", [])
      end

      private

      attr_reader :sns_message, :errors
      attr_accessor :record

      def find_or_create_record
        self.record = Analytics::SmsInboundMessage.find_or_create_by!(
          sns_message_id: sns_message.fetch("MessageId"),
        ) do |r|
          r.origination_number = inbound_payload.fetch("originationNumber")
          r.destination_number = inbound_payload.fetch("destinationNumber")
          r.message_body       = inbound_payload.fetch("messageBody")
          r.received_at        = Time.zone.parse(sns_message.fetch("Timestamp"))
          r.inbound_message_id = inbound_payload["inboundMessageId"]
          r.keyword            = parse_keyword(inbound_payload.fetch("messageBody"))
        end
      end

      def inbound_payload
        @inbound_payload ||= JSON.parse(sns_message.fetch("Message"))
      end

      def parse_keyword(body)
        first_token = body.to_s.strip.upcase.split(/\s+/).first
        KEYWORDS.include?(first_token) ? first_token : nil
      end

      def apply_state_change
        case record.keyword
        when "STOP"
          User.where(phone: record.origination_number).update_all(sms_carrier_opted_out_at: record.received_at)
        when "START"
          User.where(phone: record.origination_number).update_all(sms_carrier_opted_out_at: nil)
        end
      end
    end
  end
end
