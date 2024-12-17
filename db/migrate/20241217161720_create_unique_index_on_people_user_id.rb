class CreateUniqueIndexOnPeopleUserId < ActiveRecord::Migration[7.0]
  def change
    remove_index :people, :user_id
    add_index :people, :user_id, unique: true
  end
end
