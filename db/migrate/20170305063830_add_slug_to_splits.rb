class AddSlugToSplits < ActiveRecord::Migration
  def self.up
    add_column :splits, :slug, :string
    add_index :splits, :slug, unique: true
    Split.find_each(&:save)
    change_column_null :splits, :slug, false
  end

  def self.down
    change_column_null :splits, :slug, true
    remove_index :splits, :slug
    remove_column :splits, :slug
  end
end
