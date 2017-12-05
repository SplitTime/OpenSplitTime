module Interactors
  class DestroyEffortSplitTimes
    def self.perform!(effort, split_time_ids)
      new(effort, split_time_ids).perform!
    end

    def initialize(effort, split_time_ids)
      @effort = effort
      @split_time_ids = split_time_ids
      @errors = []
      validate_setup
    end

    def perform!
      ActiveRecord::Base.transaction do
        destroy_split_times
        raise ActiveRecord::Rollback if response.errors.present?
      end
      response
    end

    private

    def destroy_split_times
      stop_destroyed = targeted_split_times.any?(&:stopped_here)
      targeted_split_times.each { |st| errors << resource_error_object(st) unless st.destroy }
      stop_response = Interactors::UpdateEffortsStop.perform!(effort) if stop_destroyed
      self.response = Interactors::Response.new(errors, message, targeted_split_times).merge(stop_response)
    end

    attr_reader :effort, :split_time_ids, :errors, :resources
    attr_accessor :response

    def targeted_split_times
      effort.split_times.select { |st| split_time_ids.include?(st.id) }
    end

    def message
      if errors.present?
        "Split times could not be destroyed. "
      else
        "Split times #{split_time_ids} for effort #{effort} were destroyed. "
      end
    end

    def validate_setup
      raise ArgumentError, 'effort argument was not provided' unless effort
      raise ArgumentError, 'split_time_ids argument was not provided' unless split_time_ids
      raise ArgumentError, "split_time ids #{mismatched_split_time_ids.join(', ')} do not correspond to effort #{effort}" if mismatched_split_time_ids.present?
    end

    def mismatched_split_time_ids
      split_time_ids - effort.split_times.map(&:id)
    end
  end
end
