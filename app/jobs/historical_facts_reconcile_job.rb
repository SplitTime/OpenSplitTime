class HistoricalFactsReconcileJob < ApplicationJob
  queue_as :default

  def perform(parent, current_user:, personal_info_hash:, person_id:)
    set_current_user(current_user: current_user)

    HistoricalFactReconciler.reconcile(parent, personal_info_hash: personal_info_hash, person_id: person_id)
  end
end
