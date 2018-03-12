# frozen_string_literal: true

module Interactors

  # Some time data is entered based on military time, and in that case the absolute time
  # (as opposed to the elapsed time stored in the database) is more likely correct if the
  # two conflict. If an effort's start split_time is non-zero, we need to make it zero
  # and change effort.start_offset to account for the shift. But if we want existing absolute times
  # (other than the start split_time) to remain the same, we need to counter the change in offset
  # by subtracting a like amount from time_from_start in all later split_times for that effort.

  # This Class expects to receive an effort with included split_times and splits.
  # The non-zero starting split_time cannot be persisted, as it would not pass validations.

  class AdjustEffortOffset
    include Interactors::Errors

    def self.perform(effort)
      new(effort).perform
    end

    def initialize(effort)
      ArgsValidator.validate(subject: effort, subject_class: Effort, params: {})
      @effort = effort
      @start_offset_shift = start_split_time&.time_from_start || 0
      @errors = []
      validate_setup
    end

    def perform
      unless start_offset_shift.zero? || errors.present?
        adjust_start_offset
        split_times.each { |st| adjust_split_time(st) }
      end
      response
    end

    private

    attr_reader :effort, :start_offset_shift, :errors

    def adjust_start_offset
      effort.start_offset += start_offset_shift
    end

    def adjust_split_time(st)
      if st == start_split_time
        st.time_from_start = 0
      else
        st.time_from_start -= start_offset_shift
      end
    end

    def split_times
      effort.split_times
    end

    def start_split_time
      @start_split_time ||= split_times.find { |st| st.split.start? && st.lap == 1 }
    end

    def non_start_split_times
      split_times - [start_split_time]
    end

    def response
      Interactors::Response.new(errors, message, [effort])
    end

    def message
      if errors.present?
        "Unable to update effort start offset for #{effort}. "
      elsif start_offset_shift.zero?
        "Start offset for #{effort} was not changed. "
      else
        "Start offset for #{effort} was changed to #{effort.start_offset}. Split times were adjusted #{adjustment_amount} to maintain absolute times. "
      end
    end

    def adjustment_amount
      start_offset_shift.positive? ? "backward by #{start_offset_shift} seconds" : "forward by #{start_offset_shift.abs} seconds"
    end

    def validate_setup
      errors << effort_offset_failure_error(effort) if start_split_time_invalid?
    end

    def start_split_time_invalid?
      start_offset_shift.positive? && non_start_split_times.any? { |st| st.time_from_start < start_offset_shift }
    end
  end
end
