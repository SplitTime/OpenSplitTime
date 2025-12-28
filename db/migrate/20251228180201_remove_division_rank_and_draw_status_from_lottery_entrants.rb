class RemoveDivisionRankAndDrawStatusFromLotteryEntrants < ActiveRecord::Migration[7.2]
  def change
    remove_column :lottery_entrants, :division_rank, :integer
    remove_column :lottery_entrants, :draw_status, :integer
  end
end
