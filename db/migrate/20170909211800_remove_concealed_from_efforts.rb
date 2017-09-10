class RemoveConcealedFromEfforts < ActiveRecord::Migration[5.0]
  def change
    remove_column :efforts, :concealed, :boolean
  end
end
