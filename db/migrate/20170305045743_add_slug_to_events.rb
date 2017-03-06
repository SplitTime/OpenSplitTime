class AddSlugToEvents < ActiveRecord::Migration
  def self.up
    add_column :events, :slug, :string
    add_index :events, :slug, unique: true
    Event.find_each(&:save)
    change_column_null :events, :slug, false
  end

  def self.down
    change_column_null :events, :slug, true
    remove_index :events, :slug
    remove_column :events, :slug
  end
end
