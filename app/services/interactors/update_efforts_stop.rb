# frozen_string_literal: true

module Interactors
  class UpdateEffortsStop
    include Interactors::Errors

    def self.perform!(efforts, options = {})
      new(efforts, options).perform!
    end

    def initialize(efforts, options = {})
      @efforts = efforts && Array.wrap(efforts)
      @stop_status = options[:stop_status].nil? ? true : options[:stop_status]
      @errors = []
      validate_setup
    end

    def perform!
      update_response = Persist::BulkUpdateAll.perform!(SplitTime, changed_split_times, update_fields: :stopped_here)
      update_response.merge(Interactors::Response.new(errors, message, changed_split_times))
    end

    private

    attr_reader :efforts, :stop_status, :errors

    def changed_split_times
      @changed_split_times ||= stop_responses.flat_map(&:resources)
    end

    def stop_responses
      @stop_responses ||= efforts.map { |effort| Interactors::SetEffortStop.perform(effort, stop_status: stop_status) }
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
    end
  end
end
