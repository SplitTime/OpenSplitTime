# frozen_string_literal: true

module Results
  class ReportUnreconciled
    def self.perform(args)
      new(args).perform
    end

    def initialize(args)
      @efforts = args[:efforts]
      @template = args[:template]
    end

    def perform
      first_category = categories.first
      unreconciled_events = efforts.map(&:event_name).uniq
      first_category.name = "Template cannot be computed until #{unreconciled_events.to_sentence} are fully reconciled"
    end

    private

    attr_reader :sort_attribute, :efforts, :template

    def categories
      @categories ||= template.results_categories
    end
  end
end
