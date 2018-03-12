# frozen_string_literal: true

class EventDroppedDisplay < EventWithEffortsPresenter

  def dropped_effort_rows
    dropped_efforts.map { |effort| EffortRow.new(effort) }
  end

  def dropped_efforts_count
    dropped_efforts.size
  end

  private

  def dropped_efforts
    @dropped_efforts ||= ranked_efforts.select(&:dropped?)
  end
end
