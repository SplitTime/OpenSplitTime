# frozen_string_literal: true

class HistoricalFactsAutoReconcileJob < ApplicationJob
  queue_as :default

  def perform(parent, current_user:)
    set_current_user(current_user: current_user)

    HistoricalFactAutoReconciler.reconcile(parent)
  end
end
