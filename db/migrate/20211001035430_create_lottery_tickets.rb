class CreateLotteryTickets < ActiveRecord::Migration[6.1]
  def change
    create_table :lottery_tickets do |t|
      t.references :lottery_entrant, null: false, foreign_key: true
      t.references :lottery, null: false, foreign_key: true
      t.integer :reference_number, null: false

      t.timestamps

      t.index [:lottery_id, :reference_number], unique: true
    end
  end
end
