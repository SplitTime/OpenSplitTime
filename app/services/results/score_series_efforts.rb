# frozen_string_literal: true

module Results
  class ScoreSeriesEfforts
    def self.perform(series_efforts, scoring_method, event_series)
      new(series_efforts, scoring_method, event_series).perform
    end

    def initialize(series_efforts, scoring_method, event_series)
      @series_efforts = series_efforts
      @scoring_method = scoring_method.to_sym
      @event_series = event_series
      score_efforts
    end

    def perform
      score_efforts
      sorted_series_efforts
    end

    private

    attr_reader :series_efforts, :scoring_method, :event_series
    delegate :events, :results_template, to: :event_series

    def score_efforts
      events.flat_map do |event|
        event_efforts = filtered_efforts_by_event_id[event.id] || []
        Results::Compute.perform(efforts: event_efforts, template: blank_template)
      end
    end

    def sorted_series_efforts
      case scoring_method
      when :points
        filtered_series_efforts.sort_by { |series_effort| -series_effort.total_points }
      when :rank
        filtered_series_efforts.sort_by(&:total_rank)
      when :time
        filtered_series_efforts.sort_by(&:total_time_from_start)
      else
        raise RuntimeError, "Unknown scoring method #{scoring_method} "
      end
    end

    def filtered_efforts_by_event_id
      @filtered_efforts_by_event_id ||= filtered_series_efforts.flat_map(&:efforts).group_by(&:event_id)
    end

    def filtered_series_efforts
      if scoring_method == :points
        series_efforts
      else
        series_efforts.select(&:complete?)
      end
    end

    def blank_template
      results_template.dup_with_categories
    end
  end
end
