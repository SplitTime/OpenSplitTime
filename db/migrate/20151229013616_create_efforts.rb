class CreateEfforts < ActiveRecord::Migration
  def change
    create_table :efforts do |t|
      t.references :event, index: true, foreign_key: true
      t.references :participant, index: true, foreign_key: true
      t.string :wave
      t.integer :bib_number
      t.string :effort_city
      t.string :effort_state
      t.string :effort_country
      t.integer :effort_age
      t.datetime :start_time
      t.boolean :finished

      t.timestamps null: false
    end
  end
end
