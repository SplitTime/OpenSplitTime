class CreateEfforts < ActiveRecord::Migration
  def change
    create_table :efforts do |t|
      t.references :event, index: true, foreign_key: true
      t.references :participant, index: true, foreign_key: true
      t.string :wave
      t.integer :bib_number
      t.string :city
      t.string :state
      t.references :country, index: true, foreign_key: true
      t.integer :age    # age of participant at time of effort
      t.datetime :start_time
      t.boolean :finished

      t.timestamps null: false
    end
  end
end
