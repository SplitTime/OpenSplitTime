module Interactors

  # Some time data is entered based on military time, and in that case the absolute time
  # (as opposed to the elapsed time stored in the database) is more likely correct if the
  # two conflict. If an effort.start_offset changes but we want existing absolute times
  # (other than the start split_time) to remain the same, we need to counter the change in offset
  # by subtracting a like amount from time_from_start in all later split_times for that effort.

  class AdjustEffortOffset
    include Interactors::Errors

    def self.perform!(effort)
      new(effort).perform!
    end

    def initialize(effort)
      @effort = effort
      @errors = []
      validate_setup
    end

    def perform!
      unless start_offset_shift.zero?
        ActiveRecord::Base.transaction do
          errors << resource_error_object(effort) unless effort.save
          update_split_times unless errors.present?
          raise ActiveRecord::Rollback if errors.present?
        end
      end
      response
    end

    private

    attr_reader :effort, :errors

    def update_split_times
      effort.split_times.each do |st|
        next if errors.present? || st.split.start?
        st.time_from_start -= start_offset_shift
        errors << resource_error_object(st) unless st.save
      end
    end

    def start_offset_shift
      @start_time_shift ||= effort.start_offset - effort.start_offset_was
    end

    def response
      Interactors::Response.new(errors, message, {})
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
      raise ArgumentError, "arguments for #{self.class} must include effort" unless effort && effort.is_a?(Effort)
    end
  end
end
