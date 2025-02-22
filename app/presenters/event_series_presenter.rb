class EventSeriesPresenter < BasePresenter
  attr_reader :event_series

  delegate :name, :organization, :scoring_method, to: :event_series
  delegate :categories, to: :completed_template

  def initialize(event_series, view_context)
    @event_series = event_series || []
    @view_context = view_context
    @params = view_context.prepared_params
  end

  def organization_name
    organization.name
  end

  def events
    event_series.events.sort_by(&:scheduled_start_time)
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

  attr_reader :params, :view_context

  delegate :results_template, to: :event_series, private: true
  delegate :podium_size, :point_system, to: :results_template, private: true
  delegate :current_user, to: :view_context, private: true

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
    when "points"
      "on a point system using a descending scale of #{point_system.to_sentence} points for the first #{point_system.size} participants"
    when "rank"
      "by combined overall rank"
    when "time"
      "by combined finish time"
    end
  end

  def podium_size_text
    podium_size ? "#{podium_size} participant".pluralize(podium_size) : "unlimited participants"
  end
end
