class AddLotteryDivisionToLotteryDraws < ActiveRecord::Migration[7.1]
  def change
    add_reference :lottery_draws, :lottery_division, foreign_key: true
  end
end
