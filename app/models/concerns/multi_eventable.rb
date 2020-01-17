# frozen_string_literal: true

module MultiEventable
  extend ActiveSupport::Concern

  delegate :start_time, :start_time_local, to: :first_event, allow_nil: true

  def ordered_events
    events.sort_by { |event| [event.start_time, event.name] }
  end

  def first_event
    ordered_events.first
  end

  def multiple_events?
    events.many?
  end

  def multiple_laps?
    events.any?(&:multiple_laps?)
  end

  def multiple_sub_splits?
    events.any?(&:multiple_sub_splits?)
  end

  def single_lap?
    !multiple_laps?
  end
end
