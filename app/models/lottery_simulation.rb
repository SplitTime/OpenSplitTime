class LotterySimulation < ApplicationRecord
  belongs_to :simulation_run, class_name: "LotterySimulationRun", foreign_key: "lottery_simulation_run_id"

  def build
    results_array = simulation_run.divisions.ordered_by_name.map do |division|
      accepted_male_ids = division.entrants.accepted.male.order(:division_rank).pluck(:id)
      accepted_female_ids = division.entrants.accepted.female.order(:division_rank).pluck(:id)
      waitlisted_male_ids = division.entrants.waitlisted.male.order(:division_rank).pluck(:id)
      waitlisted_female_ids = division.entrants.waitlisted.female.order(:division_rank).pluck(:id)

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
            male: waitlisted_male_ids.size,
            male_entrant_ids: waitlisted_male_ids,
            female: waitlisted_female_ids.size,
            female_entrant_ids: waitlisted_female_ids,
          }
        }
      ]
    end

    self.results = results_array.to_h
    self.ticket_ids = lottery.draws.in_drawn_order.pluck(:lottery_ticket_id)
  end

  delegate :lottery, to: :simulation_run, private: true
end
