# frozen_string_literal: true

# raw_times provided to this class must be pre-loaded with relation ids
# (event_id, effort_id, split_id)
module Interactors
  class MatchRawTimesToSplitTimes
    include Interactors::Errors

    def self.perform!(args)
      new(args).perform!
    end

    def initialize(args)
      ArgsValidator.validate(params: args, required: [:event_group, :raw_times], exclusive: [:event_group, :raw_times, :tolerance], class: self.class)
      @event_group = args[:event_group]
      @raw_times = args[:raw_times]
      @tolerance = args[:tolerance] || RawTimes::Constants::MATCH_TOLERANCE
      @errors = []
      validate_setup
    end

    def perform!
      if errors.present?
        Interactors::Response.new(errors, "Raw times could not be matched. ", {})
      else
        Interactors::MatchTimeRecordsToSplitTimes.perform!(time_records: raw_times, split_times: split_times, tolerance: tolerance)
      end
    end

    private

    attr_reader :event_group, :raw_times, :tolerance, :errors

    def split_times
      SplitTime.where(effort_id: raw_times.map(&:effort_id)).with_time_record_matchers
    end
    
    def validate_setup
      errors << raw_time_mismatch_error unless raw_times.all? { |rt| rt.event_group_id == event_group.id }
    end
  end
end
