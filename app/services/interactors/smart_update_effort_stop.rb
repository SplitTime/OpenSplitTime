module Interactors
  class SmartUpdateEffortStop
    def self.perform!(effort)
      new(effort).perform!
    end

    def initialize(effort)
      @effort = effort
      validate_setup
    end

    def perform!
      return if ordered_split_times.empty?

      set_proper_final_split_time
      destroy_hanging_split_time
      set_effort_stop
      save_effort

      ::Interactors::Response.new(errors)
    end

    private

    attr_reader :effort, :errors
    attr_accessor :proper_final_split_time

    def set_proper_final_split_time
      if effort.multiple_laps?
        multi_lap_set_proper_final_split_time
      else
        single_lap_set_proper_final_split_time
      end
    end

    def multi_lap_set_proper_final_split_time
      self.proper_final_split_time = effort.split_times.find_or_initialize_by(
        lap: final_finished_lap,
        split: finish_split,
        bitkey: ::SubSplit::IN_BITKEY,
        )

      proper_final_split_time.absolute_time ||= last_split_time.absolute_time
    end

    def single_lap_set_proper_final_split_time
      self.proper_final_split_time = effort.split_times.find_or_initialize_by(
        lap: 1,
        split: last_split_time.split,
        bitkey: ::SubSplit::IN_BITKEY,
        )

      proper_final_split_time.absolute_time ||= last_split_time.absolute_time
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
      if effort.multiple_laps?
        multi_lap_hanging_split_time
      else
        single_lap_hanging_split_time
      end
    end

    def multi_lap_hanging_split_time
      last_split_time if last_split_time.start? && last_split_time.lap > 1
    end

    def single_lap_hanging_split_time
      last_split_time if last_split_time.bitkey == ::SubSplit::OUT_BITKEY
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
