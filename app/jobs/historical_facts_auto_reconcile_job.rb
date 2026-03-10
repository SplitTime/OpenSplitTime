class HistoricalFactsAutoReconcileJob < ApplicationJob
  self.queue_adapter = :solid_queue
  queue_as :solid_default

  def perform(parent, current_user:)
    set_current_user(current_user: current_user)

    HistoricalFactAutoReconciler.reconcile(parent)
  end
end
