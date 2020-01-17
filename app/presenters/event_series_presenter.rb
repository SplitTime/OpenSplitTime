# frozen_string_literal: true

class EventSeriesPresenter < BasePresenter
  attr_reader :event_series
  delegate :name, :organization, to: :event_series
  delegate :results_categories, to: :completed_template

  def initialize(event_series, params, current_user)
    @event_series = event_series || []
    @params = params
    @current_user = current_user
  end

  def organization_name
    organization.name
  end

  def events
    event_series.events.sort_by(&:start_time)
  end

  def subtext
    "Series results for #{event_series.name} scoring #{scoring_method_explanation} with #{podium_size_text} per category."
  end

  def event_result(series_effort, event)
    series_effort.send(event_result_method)[event.id]
  end

  def total_result(series_effort)
    series_effort.send(total_result_method)
  end

  private

  attr_reader :params, :current_user
  delegate :results_template, :scoring_method, to: :event_series
  delegate :podium_size, :point_system, to: :results_template

  def completed_template
    @completed_template ||= Results::FillEventSeriesTemplate.perform(event_series)
  end

  def event_result_method
    "indexed_#{scoring_method.pluralize}".to_sym
  end

  def total_result_method
    "total_#{scoring_method}".to_sym
  end

  def scoring_method_explanation
    case scoring_method
    when 'points'
      "on a point system using a descending scale of #{point_system.to_sentence} points for the first #{point_system.size} participants"
    when 'rank'
      "by combined overall rank"
    when 'time'
      "by combined finish time"
    else
      nil
    end
  end

  def podium_size_text
    podium_size ? "#{podium_size} participant".pluralize(podium_size) : 'unlimited participants'
  end
end
