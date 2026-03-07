module Interactors::Webhooks
  class ProcessRaceresultWebhook
    # The raw data is expected to be in the format: JSON_DATA;EVENT_GROUP_NAME
    def self.call(raw)
      new(raw).call
    end

    def initialize(raw)
      raise ArgumentError, "Raw data cannot be blank" if raw.blank?
      @raw = raw
    end

    def call
      parse_raw
      find_event_group
      process_data
      build_raw_time
      save_raw_time
      submit_raw_time

      raw_time
    end

    private

    attr_reader :raw
    attr_accessor :raw_attributes, :processed_attributes, :raw_time, :event_group_name, :event_group

    def parse_raw
      parts = raw.split(';')
      raise ArgumentError, "Invalid format: expected JSON;EVENT_GROUP_NAME" if parts.size != 2
      raise ArgumentError, "JSON data cannot be blank" if parts.first.blank?
      self.raw_attributes = JSON.parse(parts.first)  # Automatically raises JSON::ParserError if invalid
      raise ArgumentError, "JSON data cannot be empty" if raw_attributes.blank?
      self.event_group_name = parts.last.to_s.strip
      raise ArgumentError, "Event group name cannot be blank" if event_group_name.blank?
    end

    def find_event_group
      self.event_group = EventGroup.find_by!(name: event_group_name)
    end

    def process_data
      self.processed_attributes = {
        bib: raw_attributes["Bib"],
        utc_time: raw_attributes.dig("Passing", "UTCTime"),
        device_id: raw_attributes.dig("Passing", "DeviceID"),
        timing_point: raw_attributes["TimingPoint"],
        id: raw_attributes["ID"]
      }
      raise ArgumentError, "Missing required field: Bib" if processed_attributes[:bib].blank?
      raise ArgumentError, "Missing required field: TimingPoint" if processed_attributes[:timing_point].blank?
      raise ArgumentError, "Missing required field: Passing.UTCTime" if processed_attributes[:utc_time].blank?
      raise ArgumentError, "Missing required field: ID" if processed_attributes[:id].blank?
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