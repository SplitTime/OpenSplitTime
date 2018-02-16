module Interactors
  class MatchLiveTimes
    include Interactors::Errors

    def self.perform!(args)
      new(args).perform!
    end

    def initialize(args)
      ArgsValidator.validate(params: args,
                             required: [:event, :live_times],
                             exclusive: [:event, :live_times],
                             class: self.class)
      @event = args[:event]
      @live_times = args[:live_times]
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

    attr_reader :event, :live_times, :errors, :resources

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
      live_time.absolute_time &&
          !live_time.matched? &&
          event.split_times.where(match_attributes(live_time)).find { |st| st.day_and_time == live_time.absolute_time }
    end

    def match_attributes(live_time)
      attributes = {split: live_time.split, bitkey: live_time.bitkey}
      attributes[:pacer] = live_time.with_pacer unless live_time.with_pacer.nil?
      attributes[:stopped_here] = live_time.stopped_here unless live_time.stopped_here.nil?
      attributes
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
