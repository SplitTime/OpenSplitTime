class AddDefaultTravelBufferToGatingLocationEvents < ActiveRecord::Migration[8.1]
  def change
    add_column :gating_location_events, :default_travel_buffer, :integer, null: false, default: 30
  end
end
