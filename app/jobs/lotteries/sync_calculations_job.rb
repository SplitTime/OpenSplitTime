class Lotteries::SyncCalculationsJob < ApplicationJob
  self.queue_adapter = :solid_queue
  queue_as :solid_default

  def perform(lottery, current_user:)
    set_current_user(current_user: current_user)

    Lotteries::SyncCalculations.perform!(lottery)
  end
end
