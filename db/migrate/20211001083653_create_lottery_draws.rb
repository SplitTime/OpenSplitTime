class CreateLotteryDraws < ActiveRecord::Migration[6.1]
  def change
    create_table :lottery_draws do |t|
      t.references :lottery, null: false, foreign_key: true
      t.references :lottery_ticket, null: false, foreign_key: true

      t.timestamps
    end
  end
end
