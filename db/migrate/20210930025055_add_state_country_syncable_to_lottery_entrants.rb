class AddStateCountrySyncableToLotteryEntrants < ActiveRecord::Migration[6.1]
  def change
    add_column :lottery_entrants, :state_name, :string
    add_column :lottery_entrants, :country_name, :string
  end
end
