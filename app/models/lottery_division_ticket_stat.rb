class LotteryDivisionTicketStat < ::ApplicationRecord
  belongs_to :lottery

  def undrawn_entrants_count
    entrants_count - (accepted_entrants_count + waitlisted_entrants_count)
  end
end
