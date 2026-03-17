module Interactors
  class MatchRawTimesToSplitTimes
    include Interactors::Errors

    def self.perform!(event_group:, raw_times:, tolerance: 1.minute)
      new(event_group: event_group, raw_times: raw_times, tolerance: tolerance).perform!
    end

    def initialize(event_group:, raw_times:, tolerance: 1.minute)
      raise ArgumentError, "match_raw_times_to_split_times must include event_group" unless event_group
      raise ArgumentError, "match_raw_times_to_split_times must include raw_times" unless raw_times

      @event_group = event_group
      @raw_times = raw_times
      @tolerance = tolerance
      @errors = []
      validate_setup
    end

    def perform!
      if errors.present?
        Interactors::Response.new(errors, "Raw times could not be matched. ", {})
      else
        args = { time_records: loaded_raw_times, split_times: split_times }
        args[:tolerance] = tolerance if tolerance
        Interactors::MatchTimeRecordsToSplitTimes.perform!(**args)
      end
    end

    private

    attr_reader :event_group, :raw_times, :tolerance, :errors

    def split_times
      SplitTime.where(effort_id: loaded_raw_times.map(&:effort_id)).with_time_record_matchers
    end

    def loaded_raw_times
      RawTime.where(id: raw_times).with_relation_ids
    end

    def validate_setup
      errors << raw_time_mismatch_error unless raw_times.all? { |rt| rt.event_group_id == event_group.id }
    end
  end
end
