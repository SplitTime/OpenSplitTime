class CreateRawTimes < ActiveRecord::Migration[5.1]
  def change
    create_table :raw_times do |t|
      t.references :event_group, foreign_key: true, null: false
      t.references :split_time, foreign_key: true, null: true
      t.string :split_name, null: false
      t.integer :bitkey, null: false
      t.string :bib_number, null: false
      t.datetime :absolute_time
      t.string :entered_time
      t.boolean :with_pacer, default: false
      t.boolean :stopped_here, default: false
      t.string :source, null: false
      t.integer :pulled_by
      t.datetime :pulled_at
      t.integer :created_by
      t.integer :updated_by

      t.timestamps
    end
  end
end
