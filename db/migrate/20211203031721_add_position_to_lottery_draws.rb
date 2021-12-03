class AddPositionToLotteryDraws < ActiveRecord::Migration[6.1]
  def change
    add_column :lottery_draws, :position, :integer
  end
end
