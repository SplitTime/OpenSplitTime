module Interactors
  module Webhooks
    class ProcessRaceresultWebhook
      include Interactors::Errors

      class ParsingError < StandardError; end

      def self.call(event_group:, record:)
        new(event_group: event_group, record: record).call
      end

      def initialize(event_group:, record:)
        @event_group = event_group
        @raw_attributes = record
        @errors = []
      end

      def call
        process_data
        build_raw_time
        save_raw_time
        process_raw_time_async

        Interactors::Response.new(errors, "", [raw_time])
      rescue ParsingError => e
        errors << raceresult_parsing_error(e.message)
        Interactors::Response.new(errors, "", [])
      end

      private

      attr_reader :event_group, :raw_attributes, :errors
      attr_accessor :processed_attributes, :raw_time

      def process_data
        self.processed_attributes = {
          bib: raw_attributes["Bib"],
          utc_time: raw_attributes.dig("Passing", "UTCTime"),
          device_id: raw_attributes.dig("Passing", "DeviceID"),
          timing_point: raw_attributes["TimingPoint"],
          id: raw_attributes["ID"]
        }
        raise ParsingError, "Missing required field: Bib" if processed_attributes[:bib].blank?
        raise ParsingError, "Missing required field: TimingPoint" if processed_attributes[:timing_point].blank?
        raise ParsingError, "Missing required field: Passing.UTCTime" if processed_attributes[:utc_time].blank?
        raise ParsingError, "Missing required field: ID" if processed_attributes[:id].blank?
      end

      def build_raw_time
        self.raw_time = RawTime.new(
          event_group: event_group,
          bib_number: processed_attributes[:bib],
          split_name: processed_attributes[:timing_point],
          entered_time: processed_attributes[:utc_time],
          bitkey: SubSplit::IN_BITKEY,
          source: source_from_device_id,
          created_by: nil
        )
      end

      def source_from_device_id
        ["raceresult-webhook", processed_attributes[:device_id].presence].compact.join("-")
      end

      def save_raw_time
        raw_time.save!
      end

      def process_raw_time_async
        ProcessImportedRawTimesJob.perform_later(event_group, [raw_time])
      end
    end
  end
end
