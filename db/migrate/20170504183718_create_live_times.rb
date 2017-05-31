class CreateLiveTimes < ActiveRecord::Migration
  def change
    create_table :live_times do |t|
      t.references :event, index: true, foreign_key: true, null: false
      t.integer :lap
      t.references :split, index: true, foreign_key: true, null: false
      t.string :split_extension

      t.string :wave
      t.integer :bib_number, null: false
      t.string :absolute_time, null: false
      t.boolean :with_pacer
      t.boolean :stopped_here
      t.string :remarks

      t.integer :source
      t.string :batch
      t.datetime :recorded_at

      t.timestamps null: false
      t.integer :created_by
      t.integer :updated_by
    end
  end
end
