# frozen_string_literal: true

class AddDrawnAtToLotteryEntrants < ActiveRecord::Migration[7.2]
  def up
    execute <<~SQL.squish
      UPDATE lottery_entrants le
      SET drawn_at = x.drawn_at
      FROM (
        SELECT lt.lottery_entrant_id AS entrant_id,
               MIN(ld.created_at)     AS drawn_at
        FROM lottery_draws ld
        JOIN lottery_tickets lt
          ON lt.id = ld.lottery_ticket_id
        GROUP BY lt.lottery_entrant_id
      ) x
      WHERE le.id = x.entrant_id
        AND le.drawn_at IS NULL;
    SQL
  end

  def down
    LotteryEntrant.update_all(drawn_at: nil)
  end
end
