# frozen_string_literal: true

class EventSeriesPresenter < BasePresenter
  attr_reader :event_series
  delegate :name, :organization, :events, to: :event_series
  delegate :results_categories, to: :results_template

  def initialize(event_series, params, current_user)
    @event_series = event_series || []
    @params = params
    @current_user = current_user
  end

  def organization_name
    organization.name
  end

  private

  attr_reader :params, :current_user

  def results_template
    @results_template ||= Results::FillEventSeriesTemplate.perform(event_series)
  end
end
