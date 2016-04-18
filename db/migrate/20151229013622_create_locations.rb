class CreateLocations < ActiveRecord::Migration
  def change
    create_table :locations do |t|
      t.string :name, :null => false, limit: 64
      t.text :description
      t.integer :elevation    # stored in meters
      t.decimal :latitude, :precision => 9, :scale => 6
      t.decimal :longitude, :precision => 9, :scale => 6

      t.timestamps null: false
      t.integer :created_by, null: false
      t.integer :updated_by, null: false
    end
  end
end
