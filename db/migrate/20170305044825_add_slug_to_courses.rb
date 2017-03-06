class AddSlugToCourses < ActiveRecord::Migration
  def self.up
    add_column :courses, :slug, :string
    add_index :courses, :slug, unique: true
    Course.find_each(&:save)
    change_column_null :courses, :slug, false
  end

  def self.down
    change_column_null :courses, :slug, true
    remove_index :courses, :slug
    remove_column :courses, :slug
  end
end
