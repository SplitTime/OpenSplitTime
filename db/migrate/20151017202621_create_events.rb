class CreateEvents < ActiveRecord::Migration
  def change
    create_table :events do |t|
      t.integer :event_id
      t.string :event_name
      t.references :course, index: true, foreign_key: true
      t.date :start_date

      t.timestamps null: false
    end
    add_index :events, :event_id
  end
end
