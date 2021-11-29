# frozen_string_literal: true

module Results
  class FillEventSeriesTemplate
    def self.perform(event_series)
      new(event_series).perform
    end

    def initialize(event_series)
      @event_series = event_series
      @series_template = blank_template
    end

    def perform
      compute_series_efforts
      invalid_series_efforts = series_efforts.select(&:invalid?)

      if invalid_series_efforts.present?
        category = ResultsCategory.invalid_category(efforts: invalid_series_efforts)
        series_template.categories = [category]
      else
        Results::Compute.perform(efforts: scored_series_efforts, template: series_template)
      end

      series_template
    end

    private

    attr_reader :event_series, :series_template, :series_efforts
    delegate :scoring_method, :results_template, to: :event_series

    def blank_template
      results_template.dup_with_categories
    end

    def events
      event_series.events.sort_by(&:scheduled_start_time)
    end

    def scored_series_efforts
      Results::ScoreSeriesEfforts.perform(series_efforts, scoring_method, event_series)
    end

    def compute_series_efforts
      @series_efforts = ranked_efforts.group_by(&:person_id).map do |person_id, efforts|
        SeriesEffort.new(person: indexed_people[person_id], efforts: efforts, event_series: event_series)
      end
      @series_efforts.each(&:valid?)
    end

    def indexed_people
      @indexed_people ||= Person.where(id: event_series.efforts.select(:person_id)).index_by(&:id)
    end

    def ranked_efforts
      @ranked_efforts ||= event_series.efforts.ranked_with_status.select(&:finished?)
    end
  end
end
