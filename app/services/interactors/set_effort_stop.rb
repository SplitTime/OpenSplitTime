module Interactors
  class SetEffortStop

    def self.perform(effort, stop_status)
      new(effort, stop_status).perform
    end

    def initialize(effort, stop_status)
      @effort = effort
      @stop_status = stop_status
      validate_setup
    end

    def perform
      ordered_split_times.each { |st| st.stopped_here = false }
      split_time.stopped_here = stop_status if split_time
      Interactors::Response.new([], '', resources)
    end

    private

    attr_reader :effort, :stop_status, :errors

    def ordered_split_times
      effort.ordered_split_times.reject(&:destroyed?)
    end

    def resources
      ordered_split_times.select(&:changed?)
    end

    def split_time
      ordered_split_times.last
    end

    def validate_setup
      raise ArgumentError, 'effort is nil' unless effort
      raise ArgumentError, 'stop status is nil' if stop_status.nil?
    end
  end
end
