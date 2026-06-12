class CreateCrewPassages < ActiveRecord::Migration[8.1]
  def change
    create_table :crew_passages do |t|
      t.references :gating_location, null: false, foreign_key: true
      t.references :effort, null: false, foreign_key: true, type: :integer
      t.datetime :passed_at, null: false
      t.timestamps
    end
    add_index :crew_passages, [:gating_location_id, :effort_id], unique: true
  end
end
