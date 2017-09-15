class AddSlugToEventGroups < ActiveRecord::Migration[5.0]
  def self.up
    add_column :event_groups, :slug, :string
    add_index :event_groups, :slug, unique: true
  end

  def self.down
    remove_column :event_groups, :slug
  end
end
