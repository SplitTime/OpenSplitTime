class CreateOwnerships < ActiveRecord::Migration
  def change
    create_table :ownerships do |t|
      t.belongs_to :user, index: true, foreign_key: true, :null => false
      t.belongs_to :race, index: true, foreign_key: true, :null => false

      t.timestamps null: false
    end

    add_index :ownerships, ["user_id", "race_id"], :unique => true
  end
end
