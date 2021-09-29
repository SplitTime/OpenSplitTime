class CreateLotteryDivisions < ActiveRecord::Migration[6.1]
  def change
    create_table :lottery_divisions do |t|
      t.references :lottery, null: false, foreign_key: true
      t.string :name

      t.timestamps
    end
  end
end
