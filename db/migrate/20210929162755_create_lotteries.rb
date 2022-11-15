class CreateLotteries < ActiveRecord::Migration[6.1]
  def change
    create_table :lotteries do |t|
      t.references :organization, null: false, foreign_key: true
      t.string :name
      t.date :scheduled_start_date
      t.string :slug, null: false

      t.timestamps
    end
  end
end
