class AddPersonToLotteryEntrants < ActiveRecord::Migration[7.0]
  def change
    add_reference :lottery_entrants, :person, foreign_key: true
  end
end
