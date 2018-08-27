class CreateNotifications < ActiveRecord::Migration[5.1]
  def change
    create_table :notifications do |t|
      t.references :effort, foreign_key: true, null: false
      t.integer :distance, null: false
      t.integer :bitkey, null: false
      t.integer :follower_ids, array: true, default: []

      t.timestamps
      t.integer :created_by
      t.integer :updated_by
    end
  end
end
