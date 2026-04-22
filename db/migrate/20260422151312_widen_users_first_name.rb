class WidenUsersFirstName < ActiveRecord::Migration[8.1]
  def up
    change_column :users, :first_name, :string, limit: 64, null: false
  end

  def down
    change_column :users, :first_name, :string, limit: 32, null: false
  end
end
