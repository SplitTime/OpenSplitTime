# frozen_string_literal: true

class LotterySimulation < ApplicationRecord
  belongs_to :simulation_run, class_name: "LotterySimulationRun", foreign_key: "lottery_simulation_run_id"

  delegate :lottery, to: :simulation_run

  def build
    self.ticket_ids = lottery.draws.in_drawn_order.pluck(:ticket_id)
    self.results = simulation_run.divisions.ordered_by_name.map do |division|
      {
        division_name: division.name
      }
    end
  end
end
