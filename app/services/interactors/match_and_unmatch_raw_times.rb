# frozen_string_literal: true

module Interactors
  class MatchAndUnmatchRawTimes
    include Interactors::Errors
    include Discrepancy

    def self.perform!(args)
      new(args).perform!
    end

    def initialize(args)
      ArgsValidator.validate(params: args, required: [:split_time, :raw_time_id], exclusive: [:split_time, :raw_time_id], class: self.class)
      @split_time = args[:split_time]
      @raw_time = RawTime.find_by(id: args[:raw_time_id])
      @errors = []
      validate_setup
    end

    def perform!
      if errors.present?
        Interactors::Response.new(errors, "Raw time could not be matched. ", {})
      elsif raw_time.nil?
        Interactors::Response.new(errors, "Raw time does not exist. ", {})
      else
        conform_absolute_time
        match_raw_time
        Interactors::Response.new(errors, "Matched raw time. ", {})
      end
    end

    private

    attr_reader :split_time, :raw_time, :errors

    def conform_absolute_time
      if raw_time.absolute_time.present?
        split_time.absolute_time = raw_time.absolute_time
      else
        split_time.military_time = raw_time.military_time
      end
    end

    def match_raw_time
      raw_time.update(split_time_id: split_time.id)
    end

    def validate_setup
      return unless raw_time.present?

      errors << event_group_mismatch_error(split_time, raw_time) unless split_time.event_group_id == raw_time.event_group_id
    end
  end
end
