class CreateLocations < ActiveRecord::Migration
  def change
    create_table :locations do |t|
      t.string :name, :null => false, limit: 64
      t.integer :elevation    # stored in meters?
      t.decimal :latitude
      t.decimal :longitude

      t.timestamps null: false
    end
  end
end
