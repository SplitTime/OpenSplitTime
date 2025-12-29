# frozen_string_literal: true

class BackfillLotteryDivisionIdToLotteryTickets < ActiveRecord::Migration[7.2]
  disable_ddl_transaction!

  def up
    execute <<~SQL.squish
      UPDATE lottery_tickets lt
      SET lottery_division_id = le.lottery_division_id
      FROM lottery_entrants le
      WHERE le.id = lt.lottery_entrant_id
        AND lt.lottery_division_id IS NULL;
    SQL
  end

  def down
    LotteryTicket.update_all(lottery_division_id: nil)
  end
end
