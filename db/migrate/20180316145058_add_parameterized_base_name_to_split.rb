class AddParameterizedBaseNameToSplit < ActiveRecord::Migration[5.1]
  def up
    add_column :splits, :parameterized_base_name, :string
    Split.find_each(&:save)
    change_column_null :splits, :parameterized_base_name, false
    add_index :splits, [:parameterized_base_name, :course_id], unique: true
  end

  def down
    remove_column :splits, :parameterized_base_name, :string
  end
end
