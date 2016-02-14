class CreateRaces < ActiveRecord::Migration
  def change
    create_table :races do |t|
      t.string :name, :null => false, limit: 64

      t.timestamps null: false
      t.authorstamps :integer
    end
  end
end
