module Interactors
  class SetEffortStop

    def self.perform(effort, options = {})
      new(effort, options).perform
    end

    def initialize(effort, options = {})
      raise ArgumentError, 'arguments must include effort' unless effort
      ArgsValidator.validate(params: options, exclusive: [:stop_status, :split_time])
      @effort = effort
      @stop_status = options[:stop_status].nil? ? true : options[:stop_status]
      @split_time = options[:split_time] || ordered_split_times.last
    end

    def perform
      ordered_split_times.each { |st| st.stopped_here = false }
      split_time.stopped_here = stop_status if split_time
      Interactors::Response.new([], '', resources)
    end

    private

    attr_reader :effort, :stop_status, :split_time, :errors

    def ordered_split_times
      effort.ordered_split_times.reject(&:destroyed?)
    end

    def resources
      ordered_split_times.select(&:changed?)
    end
  end
end
