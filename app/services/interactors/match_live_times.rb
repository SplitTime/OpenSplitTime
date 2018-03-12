# frozen_string_literal: true

module Interactors
  class MatchLiveTimes
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
      @split_times = event.split_times.with_live_time_matchers
      @errors = []
      @resources = {matched_live_times: [], unmatched_live_times: []}
      validate_setup
    end

    def perform!
      unless errors.present?
        live_times.each { |lt| match_live_time_to_split_time(lt) }
      end
      Interactors::Response.new(errors, message, resources)
    end

    private

    attr_reader :event, :live_times, :tolerance, :split_times, :errors, :resources

    def match_live_time_to_split_time(live_time)
      split_time = matching_split_time(live_time)
      if split_time
        live_time.update(split_time: split_time)
        matched_live_times << live_time
      else
        unmatched_live_times << live_time
      end
    end

    def matching_split_time(live_time)
      !live_time.matched? && split_times.find { |split_time| matching_record(split_time, live_time) }
    end

    def matching_record(split_time, live_time)
      (split_time.split_id == live_time.split_id) &&
          (split_time.bitkey == live_time.bitkey) &&
          (split_time.bib_number.to_s == live_time.bib_number) &&
          ((live_time.stopped_here || false) == (split_time.stopped_here || false)) &&
          ((live_time.with_pacer || false) == (split_time.pacer || false)) &&
          time_matches(split_time, live_time)
    end

    def time_matches(split_time, live_time)
      (live_time.absolute_time && (split_time.day_and_time - live_time.absolute_time).abs <= tolerance) ||
          (live_time.entered_time && (Time.parse(split_time.military_time) - Time.parse(live_time.entered_time)).abs <= tolerance)
    end

    def matched_live_times
      resources[:matched_live_times]
    end

    def unmatched_live_times
      resources[:unmatched_live_times]
    end

    def message
      "Matched #{matched_live_times.size} live times. Did not match #{unmatched_live_times.size} live times. "
    end

    def validate_setup
      errors << live_time_mismatch_error unless live_times.all? { |lt| lt.event_id == event.id }
    end
  end
end
