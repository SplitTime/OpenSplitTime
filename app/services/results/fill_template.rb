module Results
  class FillTemplate
    def self.perform(args)
      new(args).perform
    end

    def initialize(args)
      @event = args[:event]
      @template = Results::Templates.find(args[:template_name])
    end

    def perform
      Results::Compute.perform(efforts: event.efforts.ranked_with_finish_status,
                               categories: template.categories,
                               podium_size: template.podium_size,
                               method: template.method)
      template
    end

    private

    attr_reader :event, :template
  end
end
