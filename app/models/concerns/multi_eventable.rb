# frozen_string_literal: true

module MultiEventable
  extend ActiveSupport::Concern

  delegate :scheduled_start_time, :scheduled_start_time_local, to: :first_event, allow_nil: true

  def ordered_events
    events.sort_by { |event| [event.scheduled_start_time, event.name] }
  end

  def first_event
    ordered_events.first
  end

  def maximum_laps
    laps_required_array = events.map(&:laps_required)
    laps_required_array.min == 0 ? nil : laps_required_array.max
  end

  def multiple_events?
    events.many?
  end

  def multiple_laps?
    events.any?(&:multiple_laps?)
  end
  alias_method :multi_lap, :multiple_laps?

  def multiple_sub_splits?
    events.any?(&:multiple_sub_splits?)
  end

  def single_lap?
    !multiple_laps?
  end
end
