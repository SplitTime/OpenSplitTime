# frozen_string_literal: true

class LotterySimulation < ApplicationRecord
  belongs_to :simulation_run, class_name: "LotterySimulationRun", foreign_key: "lottery_simulation_run_id"

  def build
    results_array = simulation_run.divisions.ordered_by_name.map do |division|
      accepted_male_ids = ::LotteryEntrant.from(division.accepted_entrants, :lottery_entrants).male.order(:drawn_at).pluck(:id)
      accepted_female_ids = ::LotteryEntrant.from(division.accepted_entrants, :lottery_entrants).female.order(:drawn_at).pluck(:id)
      wait_list_male_ids = ::LotteryEntrant.from(division.wait_list_entrants, :lottery_entrants).male.order(:drawn_at).pluck(:id)
      wait_list_female_ids = ::LotteryEntrant.from(division.wait_list_entrants, :lottery_entrants).female.order(:drawn_at).pluck(:id)

      [
        division.name,
        {
          accepted: {
            male: accepted_male_ids.size,
            male_entrant_ids: accepted_male_ids,
            female: accepted_female_ids.size,
            female_entrant_ids: accepted_female_ids,
          },
          wait_list: {
            male: wait_list_male_ids.size,
            male_entrant_ids: wait_list_male_ids,
            female: wait_list_female_ids.size,
            female_entrant_ids: wait_list_female_ids,
          }
        }
      ]
    end

    self.results = results_array.to_h
    self.ticket_ids = lottery.draws.in_drawn_order.pluck(:lottery_ticket_id)
  end

  delegate :lottery, to: :simulation_run, private: true
end
