class ChangeNullablesForLotteryDraws < ActiveRecord::Migration[7.1]
  def change
    change_column_null :lottery_draws, :lottery_division_id, false
    change_column_null :lottery_draws, :lottery_id, true
  end
end
