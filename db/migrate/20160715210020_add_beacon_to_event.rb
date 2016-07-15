class AddBeaconToEvent < ActiveRecord::Migration
  def change
    add_column :events, :beacon_url, :string
  end
end
