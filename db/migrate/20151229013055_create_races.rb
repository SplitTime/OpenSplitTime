class CreateRaces < ActiveRecord::Migration
  def change
    create_table :races do |t|
      t.string :name, :null => false, limit: 64
      t.text :description

      t.timestamps null: false
      t.integer :created_by, null: false
      t.integer :updated_by, null: false
    end
  end
end
