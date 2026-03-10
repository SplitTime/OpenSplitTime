class HistoricalFactsReconcileJob < ApplicationJob
  self.queue_adapter = :solid_queue
  queue_as :solid_default

  def perform(parent, current_user:, personal_info_hash:, person_id:)
    set_current_user(current_user: current_user)

    HistoricalFactReconciler.reconcile(parent, personal_info_hash: personal_info_hash, person_id: person_id)
  end
end
