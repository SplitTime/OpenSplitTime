# frozen_string_literal: true

module Results
  class FillEventTemplate
    # @param [::Event] event
    # @return [::ResultsTemplate]
    def self.perform(event)
      new(event).perform
    end

    def initialize(event)
      @event = event
      @template = event.results_template.dup_with_categories
    end

    # @return [::ResultsTemplate]
    def perform
      Results::Compute.perform(efforts: efforts, template: template)
      template
    end

    # @return [Array<::Effort>]
    def efforts
      ranked_efforts = event.efforts.finish_info_subquery

      if event.laps_unlimited?
        ranked_efforts.select(&:beyond_start?)
      else
        ranked_efforts.select(&:finished?)
      end
    end

    private

    attr_reader :event, :template
  end
end
