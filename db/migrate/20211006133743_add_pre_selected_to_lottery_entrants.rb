class AddPreSelectedToLotteryEntrants < ActiveRecord::Migration[6.1]
  def change
    add_column :lottery_entrants, :pre_selected, :boolean, default: false
  end
end
