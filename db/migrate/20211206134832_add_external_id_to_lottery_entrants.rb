class AddExternalIdToLotteryEntrants < ActiveRecord::Migration[6.1]
  def change
    add_column :lottery_entrants, :external_id, :string
  end
end
