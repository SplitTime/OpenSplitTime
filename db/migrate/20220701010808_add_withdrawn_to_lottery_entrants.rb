class AddWithdrawnToLotteryEntrants < ActiveRecord::Migration[7.0]
  def change
    add_column :lottery_entrants, :withdrawn, :boolean
  end
end
