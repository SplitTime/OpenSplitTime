class CreateFriendships < ActiveRecord::Migration
  def change
    create_table :friendships do |t|
      t.belongs_to :user, index: true, foreign_key: true
      t.belongs_to :participant, index: true, foreign_key: true
      t.integer :type

      t.timestamps null: false
    end
  end
end
