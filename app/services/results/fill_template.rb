# frozen_string_literal: true

module Results
  class FillTemplate
    def self.perform(args)
      new(args).perform
    end

    def initialize(args)
      @event = args[:event]
      @template = Results::Templates.find(args[:template_name]) if args[:template_name]
    end

    def perform
      return nil unless template
      Results::Compute.perform(efforts: efforts,
                               categories: template.categories,
                               podium_size: template.podium_size,
                               method: template.method)
      template
    end

    def efforts
      event.efforts.ranked_with_finish_status.select(&:finished)
    end

    private

    attr_reader :event, :template
  end
end
