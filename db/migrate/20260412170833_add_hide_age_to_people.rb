class AddHideAgeToPeople < ActiveRecord::Migration[8.1]
  def change
    add_column :people, :hide_age, :boolean, null: false, default: false
  end
end
