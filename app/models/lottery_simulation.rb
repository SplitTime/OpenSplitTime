# frozen_string_literal: true

class LotterySimulation < ApplicationRecord
  belongs_to :simulation_run, class_name: "LotterySimulationRun", foreign_key: "lottery_simulation_run_id"

  def build
    results_array = simulation_run.divisions.ordered_by_name.map do |division|
      [
        division.name,
        {
          accepted: {
            male: ::LotteryEntrant.from(division.winning_entrants, :lottery_entrants).male.count,
            female: ::LotteryEntrant.from(division.winning_entrants, :lottery_entrants).female.count,
          },
          wait_list: {
            male: ::LotteryEntrant.from(division.wait_list_entrants, :lottery_entrants).male.count,
            female: ::LotteryEntrant.from(division.wait_list_entrants, :lottery_entrants).female.count,
          }
        }
      ]
    end

    self.results = results_array.to_h
    self.ticket_ids = lottery.draws.in_drawn_order.pluck(:lottery_ticket_id)
  end

  delegate :lottery, to: :simulation_run, private: true
end
