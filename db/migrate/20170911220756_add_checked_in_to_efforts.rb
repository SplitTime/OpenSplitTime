class AddCheckedInToEfforts < ActiveRecord::Migration[5.0]
  def change
    add_column :efforts, :checked_in, :boolean, default: false
  end
end
