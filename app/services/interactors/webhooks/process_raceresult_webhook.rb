module Interactors
  module Webhooks
    class ProcessRaceresultWebhook
      include Interactors::Errors

      class ParsingError < StandardError; end

      # The raw data is expected to be in the format: JSON_DATA;EVENT_GROUP_NAME
      def self.call(raw)
        new(raw).call
      end

      def initialize(raw)
        @raw = raw
        @errors = []
      end

      def call
        parse_raw
        find_event_group
        process_data
        build_raw_time
        save_raw_time
        submit_raw_time

        Interactors::Response.new(errors, "", [raw_time])
      rescue ParsingError => e
        errors << raceresult_parsing_error(e.message)
        Interactors::Response.new(errors, "", [])
      end

      private

      attr_reader :raw
      attr_accessor :raw_attributes, :processed_attributes, :raw_time, :event_group_name, :event_group, :errors

      def parse_raw
        parts = raw.split(";")
        raise ParsingError, "Invalid format: expected JSON;EVENT_GROUP_NAME" if parts.size != 2

        raise ParsingError, "JSON data cannot be blank" if parts.first.blank?

        self.raw_attributes = JSON.parse(parts.first) # Automatically raises JSON::ParserError if invalid

        raise ParsingError, "JSON data cannot be empty" if raw_attributes.blank?

        self.event_group_name = parts.last.to_s.strip
        raise ParsingError, "Event group name cannot be blank" if event_group_name.blank?
      end

      def find_event_group
        self.event_group = EventGroup.find_by(slug: event_group_name.parameterize)
        raise ParsingError, "Event group not found: #{event_group_name}" unless event_group
      end

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
          source: "raceresult_webhook",
          created_by: nil
        )
      end

      def save_raw_time
        raw_time.save!
      end

      def submit_raw_time
        raw_time_rows = RowifyRawTimes.build(event_group: event_group, raw_times: [raw_time])

        Interactors::SubmitRawTimeRows.perform!(
          raw_time_rows: raw_time_rows,
          event_group: event_group,
          force_submit: false,
          mark_as_reviewed: false,
          current_user_id: nil
        )
      end
    end
  end
end
