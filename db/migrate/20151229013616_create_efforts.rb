class CreateEfforts < ActiveRecord::Migration
  def change
    create_table :efforts do |t|
      t.references :event, index: true, foreign_key: true, :null => false
      t.references :participant, index: true, foreign_key: true
      t.string :wave
      t.integer :bib_number
      t.string :city, limit: 64
      t.string :state, limit: 64
      t.references :country, index: true, foreign_key: true
      t.integer :age    # age of participant at time of effort
      t.datetime :start_time, :null => false
      t.boolean :finished

      t.timestamps null: false
      t.integer :created_by, null: false
      t.integer :updated_by, null: false
    end
  end
end
