class AddCommentsToEfforts < ActiveRecord::Migration[5.2]
  def change
    add_column :efforts, :comments, :string
  end
end
