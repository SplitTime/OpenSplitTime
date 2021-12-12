# frozen_string_literal: true

class LotterySimulation < ApplicationRecord
  belongs_to :simulation_run, class_name: "LotterySimulationRun", foreign_key: "lottery_simulation_run_id"

  delegate :lottery, to: :simulation_run

  def build
    self.ticket_ids = lottery.draws.in_drawn_order.pluck(:ticket_id)
    self.results = simulation_run.divisions.ordered_by_name.map do |division|
      {
        division_name: division.name,
        accepted: {
          male: division.winning_entrants.male.count,
          female: division.winning_entrants.female.count
        },
        wait_list: {
          male: division.wait_list_entrants.male.count,
          female: division.wait_list_entrants.female.count
        }
      }
    end
  end
end
