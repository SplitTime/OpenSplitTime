class SplitsSubdivideName < ActiveRecord::Migration
  def self.up
    add_column :splits, :base_name, :string
    add_column :splits, :name_extension, :string
    execute("UPDATE splits SET base_name = ARRAY_TO_STRING(array_remove(array_remove(STRING_TO_ARRAY(name, ' '), 'In'), 'Out'), ' ')")
    execute("UPDATE splits SET name_extension = trim(replace(name, base_name, ''))")
    execute("UPDATE splits SET name_extension = NULLIF(name_extension, '')")
    remove_column :splits, :name
  end

  def self.down
    add_column :splits, :name, :string
    execute("UPDATE splits SET name = (ARRAY_TO_STRING(ARRAY[base_name, name_extension], ' '))")
    remove_column :splits, :base_name
    remove_column :splits, :name_extension
  end
end
