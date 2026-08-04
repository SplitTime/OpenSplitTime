class RecomputeEffortPerformanceDataJob < ApplicationJob
  queue_as :default

  # Self-healing entry point for page views: authorized viewers of an event
  # with stale performance data trigger a recompute in the background. The
  # recompute is idempotent, so duplicate enqueues before the first run are
  # harmless.
  def self.enqueue_if_stale(event, user)
    return unless user&.authorized_to_edit?(event)
    return unless event.performance_data_stale?

    perform_later([event.id])
  end

  def perform(event_ids)
    Event.where(id: event_ids).find_each do |event|
      effort_ids = event.efforts.pluck(:id)
      next if effort_ids.empty?

      Results::SetEffortPerformanceData.perform!(effort_ids)
      event.efforts.touch_all
      event.touch
    end
  end
end
