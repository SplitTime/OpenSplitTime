# frozen_string_literal: true

class LotterySimulationRun < ApplicationRecord
  belongs_to :lottery
  has_many :simulations, class_name: "LotterySimulation", dependent: :destroy

  enum status: {
    waiting: 0,
    processing: 1,
    finished: 2,
    failed: 3
  }

  def set_elapsed_time!
    return unless persisted? && started_at.present?

    update_column(:elapsed_time, Time.current - started_at)
  end

  def start!
    update(started_at: ::Time.current)
  end
end
