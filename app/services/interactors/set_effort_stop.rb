# frozen_string_literal: true

module Interactors
  class SetEffortStop

    def self.perform(effort, options = {})
      new(effort, options).perform
    end

    def initialize(effort, options = {})
      ArgsValidator.validate(subject: effort, subject_class: Effort, params: options, exclusive: [:stop_status, :split_time_id])
      @effort = effort
      @stop_status = options[:stop_status].nil? ? true : options[:stop_status]
      @split_time_id = options[:split_time_id]
      validate_setup
    end

    def perform
      ordered_split_times.each { |st| st.stopped_here = false }
      split_time.stopped_here = stop_status if split_time
      Interactors::Response.new([], '', resources)
    end

    private

    attr_reader :effort, :stop_status, :split_time_id, :errors

    def ordered_split_times
      @ordered_split_times ||= effort.ordered_split_times.reject(&:destroyed?)
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
      raise ArgumentError, "split_time_id #{split_time_id} does not exist for #{effort}" if split_time_id && !found_split_time
    end
  end
end
