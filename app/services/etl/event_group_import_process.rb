# frozen_string_literal: true

module ETL
  class EventGroupImportProcess
    include BackgroundNotifiable

    def self.perform!(event_group, importer)
      new(event_group, importer).perform!
    end

    def initialize(event_group, importer)
      @event_group = event_group
      @importer = importer
    end

    def perform!
      process_raw_times
    end

    private

    attr_reader :event_group, :importer

    def process_raw_times
      raw_times = grouped_records[RawTime]
      if raw_times.present?
        match_response = Interactors::MatchRawTimes.perform!(event_group: event_group, raw_times: raw_times)
        unmatched_raw_times = match_response.resources[:unmatched]
        Interactors::CreateSplitTimesFromRawTimes.perform!(event_group: event_group, raw_times: unmatched_raw_times) if event_group.auto_live_times?
        report_live_times_available(event_group)
      end
    end

    def grouped_records
      @grouped_records ||= importer.saved_records.group_by(&:class)
    end
  end
end
