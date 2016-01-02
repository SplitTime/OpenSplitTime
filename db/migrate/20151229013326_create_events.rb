class CreateEvents < ActiveRecord::Migration
  def change
    create_table :events do |t|
      t.references :course, index: true, foreign_key: true
      t.references :race, index: true, foreign_key: true
      t.string :name
      t.date :start_date

      t.timestamps null: false
    end
  end
end
