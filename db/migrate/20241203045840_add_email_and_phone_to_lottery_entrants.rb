class AddEmailAndPhoneToLotteryEntrants < ActiveRecord::Migration[7.0]
  def change
    add_column :lottery_entrants, :email, :string
    add_column :lottery_entrants, :phone, :string
  end
end
