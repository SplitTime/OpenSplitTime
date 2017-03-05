class AddSlugToOrganizations < ActiveRecord::Migration
  def self.up
    add_column :organizations, :slug, :string
    add_index :organizations, :slug, unique: true
    Organization.find_each(&:save)
    change_column_null :organizations, :slug, false
  end

  def self.down
    change_column_null :organizations, :slug, true
    remove_index :organizations, :slug
    remove_column :organizations, :slug
  end
end
