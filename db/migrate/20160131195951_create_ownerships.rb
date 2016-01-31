class CreateOwnerships < ActiveRecord::Migration
  def change
    create_table :ownerships do |t|
      t.integer :user_id, index: true, foreign_key: true
      t.integer :race_id, index: true, foreign_key: true

      t.timestamps null: false
    end
  end
end
