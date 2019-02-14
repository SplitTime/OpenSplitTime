# frozen_string_literal: true

module Results
  class FillTemplate
    def self.perform(args)
      new(args).perform
    end

    def initialize(args)
      @event = args[:event]
      @template = event.results_template
    end

    def perform
      return nil unless template
      Results::Compute.perform(efforts: efforts,
                               categories: template.results_categories,
                               podium_size: template.podium_size,
                               method: template.aggregation_method,
                               point_system: template.point_system)
      template
    end

    def efforts
      event.efforts.ranked_with_status.select(&:finished)
    end

    private

    attr_reader :event, :template
  end
end
