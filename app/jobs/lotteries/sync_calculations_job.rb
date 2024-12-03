# frozen_string_literal: true

class Lotteries::SyncCalculationsJob < ApplicationJob
  queue_as :default

  def perform(lottery, current_user:)
    set_current_user(current_user: current_user)

    Lotteries::SyncCalculations.perform!(lottery)
  end
end
