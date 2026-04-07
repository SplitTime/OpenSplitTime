module Interactors
  class ResetEffortPerformanceData
    include Interactors::Errors

    def self.perform!(event)
      new(event).perform!
    end

    def initialize(event)
      @event = event
      @errors = []
    end

    def perform!
      stale_effort_ids.each { |id| Results::SetEffortPerformanceData.perform!(id) }
      Interactors::Response.new(errors, response_message)
    rescue ActiveRecord::ActiveRecordError => e
      errors << active_record_error(e)
      Interactors::Response.new(errors, response_message)
    end

    private

    attr_reader :event, :errors

    def stale_effort_ids
      @stale_effort_ids ||= event.efforts.started
                                 .where.missing(:split_times)
                                 .pluck(:id)
    end

    def response_message
      if errors.present?
        "Unable to reset effort performance data"
      elsif stale_effort_ids.any?
        "Reset performance data for #{stale_effort_ids.size} #{'effort'.pluralize(stale_effort_ids.size)}"
      end
    end
  end
end
