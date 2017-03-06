class AddSlugToUsers < ActiveRecord::Migration
  def self.up
    add_column :users, :slug, :string
    add_index :users, :slug, unique: true
    User.find_each(&:save)
    change_column_null :users, :slug, false
  end

  def self.down
    change_column_null :users, :slug, true
    remove_index :users, :slug
    remove_column :users, :slug
  end
end
