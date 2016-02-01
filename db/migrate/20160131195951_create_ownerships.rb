class CreateOwnerships < ActiveRecord::Migration
  def change
    create_table :ownerships do |t|
      t.belongs_to :user_id, index: true, foreign_key: true
      t.belongs_to :race_id, index: true, foreign_key: true

      t.timestamps null: false
    end
  end
end
