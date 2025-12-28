class AddDrawnAtToLotteryEntrants < ActiveRecord::Migration[7.2]
  def change
    add_column :lottery_entrants, :drawn_at, :datetime

    add_index :lottery_entrants, [:lottery_division_id, :drawn_at, :id]
    add_index :lottery_entrants, [:lottery_division_id, :withdrawn, :drawn_at, :id]
  end
end
