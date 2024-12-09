# frozen_string_literal: true

class Lotteries::DivisionRanking < ApplicationRecord
  self.primary_key = :lottery_entrant_id
  self.table_name = "lotteries_division_rankings"

  belongs_to :lottery_entrant

  enum :draw_status,
       {
         accepted: 0,
         waitlisted: 1,
         drawn_beyond_waitlist: 2,
         not_drawn: 3,
       }

end
