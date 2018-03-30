# frozen_string_literal: true

module Interactors
  class MatchLiveTimesToSplitTimes
    include Interactors::Errors

    def self.perform!(args)
      new(args).perform!
    end

    def initialize(args)
      ArgsValidator.validate(params: args,
                             required: [:event, :live_times],
                             exclusive: [:event, :live_times, :tolerance],
                             class: self.class)
      @event = args[:event]
      @live_times = args[:live_times]
      @tolerance = args[:tolerance] || 1.minute
      @split_times = event.split_times.with_time_record_matchers
      @errors = []
      validate_setup
    end

    def perform!
      if errors.present?
        Interactors::Response.new(errors, "Live times could not be matched. ")
      else
        Interactors::MatchTimeRecordsToSplitTimes.perform!(time_records: live_times, split_times: split_times, tolerance: tolerance)
      end
    end

    private

    attr_reader :event, :live_times, :tolerance, :split_times, :errors

    def validate_setup
      errors << live_time_mismatch_error unless live_times.all? { |lt| lt.event_id == event.id }
    end
  end
end
