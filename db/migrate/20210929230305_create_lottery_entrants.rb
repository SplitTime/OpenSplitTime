class CreateLotteryEntrants < ActiveRecord::Migration[6.1]
  def change
    create_table :lottery_entrants do |t|
      t.references :lottery_division, null: false, foreign_key: true
      t.string :first_name, null: false
      t.string :last_name, null: false
      t.integer :gender, null: false
      t.integer :number_of_tickets, null: false
      t.string :birthdate
      t.string :city
      t.string :state_code
      t.string :country_code

      t.timestamps
    end
  end
end
