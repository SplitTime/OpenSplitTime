# frozen_string_literal: true

module Results
  class FillEventSeriesTemplate
    def self.perform(event_series)
      new(event_series).perform
    end

    def initialize(event_series)
      @event_series = event_series
      @series_template = event_series.results_template.dup_with_categories
    end

    def perform
      unreconciled_efforts = event_series.efforts.select(&:unreconciled?)

      if unreconciled_efforts.present?
        Results::ReportUnreconciled.perform(efforts: unreconciled_efforts, template: series_template)
      else
        Results::Compute.perform(efforts: sorted_series_efforts, template: series_template)
      end

      series_template
    end

    private

    attr_reader :event_series, :series_template

    def all_event_efforts
      @all_event_efforts = events.flat_map do |event|
        event_template = series_template.dup_with_categories
        event_efforts = event.efforts.ranked_with_status.select(&:finished?)
        Results::Compute.perform(efforts: event_efforts, template: event_template)
        event_efforts
      end
    end

    def events
      event_series.events.sort_by(&:start_time)
    end

    def sorted_series_efforts
      series_efforts.sort_by { |effort| -effort.total_points }
    end

    def series_efforts
      all_event_efforts.group_by(&:person_id).map do |person_id, efforts|
        SeriesEffort.new(person: indexed_people[person_id], efforts: efforts)
      end
    end

    def person_ids
      all_event_efforts.map(&:person_id).uniq
    end

    def indexed_people
      @indexed_people ||= Person.find(person_ids).index_by(&:id)
    end
  end
end
