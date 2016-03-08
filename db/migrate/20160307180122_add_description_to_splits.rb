class AddDescriptionToSplits < ActiveRecord::Migration
  def change
    add_column :splits, :description, :string
  end
end
