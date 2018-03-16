class AddIndexToSplitsBaseName < ActiveRecord::Migration[5.1]
  def up
    change_column_null :splits, :base_name, false
    add_index :splits, [:base_name, :course_id], unique: true
  end

  def down
    remove_index :splits, [:base_name, :course_id]
  end
end
