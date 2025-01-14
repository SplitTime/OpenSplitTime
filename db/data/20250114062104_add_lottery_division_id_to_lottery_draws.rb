# frozen_string_literal: true

class AddLotteryDivisionIdToLotteryDraws < ActiveRecord::Migration[7.1]
  def up
    execute <<-SQL.squish
      WITH draw_to_division AS (
        SELECT 
          lottery_draws.id AS draw_id,
          lottery_entrants.lottery_division_id AS lottery_division_id
        FROM lottery_draws
        INNER JOIN lottery_tickets ON lottery_tickets.id = lottery_draws.lottery_ticket_id
        INNER JOIN lottery_entrants ON lottery_entrants.id = lottery_tickets.lottery_entrant_id
      )
      UPDATE lottery_draws
      SET lottery_division_id = draw_to_division.lottery_division_id
      FROM draw_to_division
      WHERE lottery_draws.id = draw_to_division.draw_id;
    SQL
  end

  def down
    LotteryDraw.update_all(lottery_division_id: nil)
  end
end
