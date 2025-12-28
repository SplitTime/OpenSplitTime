class AddDivisionRankAndDrawStatusToLotteryEntrants < ActiveRecord::Migration[7.2]
  def change
    add_column :lottery_entrants, :division_rank, :integer
    add_column :lottery_entrants, :draw_status, :integer
  end
end
