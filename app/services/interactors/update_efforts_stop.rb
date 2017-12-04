module Interactors
  class UpdateEffortsStop
    include Interactors::Errors

    def self.perform!(efforts, stop_status)
      new(efforts, stop_status).perform!
    end

    def initialize(efforts, stop_status)
      @efforts = efforts && Array.wrap(efforts)
      @stop_status = stop_status
      @errors = []
      validate_setup
    end

    def perform!
      result = SplitTime.import(changed_split_times, on_duplicate_key_update: [:stopped_here])
      unless result.failed_instances.empty?
        result.failed_instances.each { |resource| errors << resource_error_object(resource) }
      end
      Interactors::Response.new(errors, message, changed_split_times)
    end

    private

    attr_reader :efforts, :stop_status, :errors

    def changed_split_times
      @changed_split_times ||= stop_responses.map(&:resources).flatten
    end

    def stop_responses
      @stop_responses ||= efforts.map { |effort| Interactors::SetEffortStop.perform(effort, stop_status) }
    end

    def message
      if errors.empty?
        "Updated #{changed_efforts_size} efforts and #{changed_split_times.size} split times. "
      else
        "Could not update efforts. "
      end
    end

    def changed_efforts_size
      stop_responses.select { |response| response.resources.present? }.size
    end

    def validate_setup
      raise ArgumentError, 'efforts argument was not provided' unless efforts
      raise ArgumentError, 'stop_status argument was not provided' if stop_status.nil?
    end
  end
end
