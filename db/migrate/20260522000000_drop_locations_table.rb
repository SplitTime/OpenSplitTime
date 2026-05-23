class DropLocationsTable < ActiveRecord::Migration[8.1]
  def change
    remove_foreign_key :splits, :locations
    remove_index :splits, :location_id
    remove_column :splits, :location_id, :integer

    drop_table :locations, id: :serial do |t|
      t.datetime "created_at", precision: nil, null: false
      t.integer "created_by"
      t.text "description"
      t.float "elevation"
      t.decimal "latitude", precision: 9, scale: 6
      t.decimal "longitude", precision: 9, scale: 6
      t.string "name", limit: 64, null: false
      t.datetime "updated_at", precision: nil, null: false
      t.integer "updated_by"
    end
  end
end
