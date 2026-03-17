module Interactors
  class SetEffortStop
    def self.perform(effort, **)
      new(effort, **).perform
    end

    def initialize(effort, stop_status: nil, split_time_id: nil)
      raise ArgumentError, "set_effort_stop must include effort" unless effort
      raise ArgumentError, "effort must be an Effort" unless effort.is_a?(Effort)

      @effort = effort
      @stop_status = stop_status.nil? ? true : stop_status
      @split_time_id = split_time_id
      validate_setup
    end

    def perform
      ordered_split_times.each { |st| st.stopped_here = false }
      split_time.stopped_here = stop_status if split_time
      Interactors::Response.new([], "", resources)
    end

    private

    attr_reader :effort, :stop_status, :split_time_id, :errors

    def ordered_split_times
      @ordered_split_times ||= effort.ordered_split_times.reject { |st| st.destroyed? || st.marked_for_destruction? }
    end

    def split_time
      split_time_id.nil? ? ordered_split_times.last : found_split_time
    end

    def found_split_time
      ordered_split_times.find { |st| st.id == split_time_id }
    end

    def resources
      ordered_split_times.select(&:changed?)
    end

    def validate_setup
      return unless split_time_id && !found_split_time

      raise ArgumentError, "split_time_id #{split_time_id} does not exist for #{effort}"
    end
  end
end
