class AddCarmenLocationCodesToEfforts < ActiveRecord::Migration
  def change
    add_column :efforts, :country_code, :string, limit: 2
    rename_column :efforts, :state, :state_code
    remove_column :efforts, :country_id
  end
end
