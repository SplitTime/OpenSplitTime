class RemoveLotteryIdFromLotteryDraws < ActiveRecord::Migration[8.1]
  def change
    remove_column :lottery_draws, :lottery_id, :bigint
  end
end
