class AddCarmenLocationCodesToParticipants < ActiveRecord::Migration
  def change
    add_column :participants, :country_code, :string, limit: 2
    rename_column :participants, :state, :state_code
    remove_column :participants, :country_id
  end
end
