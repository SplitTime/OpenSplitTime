class UpdateUserSeparateFirstLastNames < ActiveRecord::Migration
  def change
    add_column :users, :first_name, :string, limit: 32
    add_column :users, :last_name, :string, limit: 64
    remove_column :users, :name, :string
  end
end
