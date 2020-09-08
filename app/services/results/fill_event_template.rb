# frozen_string_literal: true

module Results
  class FillEventTemplate
    def self.perform(event)
      new(event).perform
    end

    def initialize(event)
      @event = event
      @template = event.results_template.dup_with_categories
    end

    def perform
      Results::Compute.perform(efforts: efforts, template: template)
      template
    end

    def efforts
      event.efforts.ranked_with_status.select(&:finished)
    end

    private

    attr_reader :event, :template
  end
end
