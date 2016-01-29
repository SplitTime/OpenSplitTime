class CreateFriendships < ActiveRecord::Migration
  def change
    create_table :friendships do |t|
      t.integer :user_id
      t.integer :participant_id
      t.integer :type

      t.timestamps null: false
    end
  end
end
