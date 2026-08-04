class RecomputeEffortPerformanceDataJob < ApplicationJob
  queue_as :default

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
