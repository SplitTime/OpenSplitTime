# frozen_string_literal: true

module Interactors
  class FixMultiLapEffortStop
    def self.perform!(effort)
      new(effort).perform!
    end

    def initialize(effort)
      @effort = effort
      validate_setup
    end

    def perform!
      return if ordered_split_times.empty?

      set_finish_split_time
      destroy_hanging_split_time
      set_effort_stop
      save_effort

      ::Interactors::Response.new(errors)
    end

    private

    attr_reader :effort, :errors
    attr_accessor :finish_split_time

    def set_finish_split_time
      self.finish_split_time = effort.split_times.find_or_initialize_by(
        lap: final_finished_lap,
        split: finish_split,
        bitkey: ::SubSplit::IN_BITKEY,
        )

      finish_split_time.absolute_time ||= last_split_time.absolute_time
    end

    def destroy_hanging_split_time
      hanging_split_time&.mark_for_destruction
    end

    def set_effort_stop
      ::Interactors::SetEffortStop.perform(effort)
    end

    def save_effort
      effort.save
      errors << resource_error_object(effort) if effort.errors.present?
    end

    def final_finished_lap
      hanging_split_time? ? last_split_time.lap - 1 : last_split_time.lap
    end

    def finish_split
      effort.ordered_splits.find(&:finish?)
    end

    def hanging_split_time
      return unless last_split_time.start? && last_split_time.lap > 1

      last_split_time
    end

    def hanging_split_time?
      hanging_split_time.present?
    end

    def last_split_time
      ordered_split_times.last
    end

    def ordered_split_times
      @ordered_split_times ||= effort.ordered_split_times.reject { |st| st.destroyed? || st.marked_for_destruction? }
    end

    def validate_setup
      errors << finish_split_missing_error unless finish_split.present?
    end
  end
end
