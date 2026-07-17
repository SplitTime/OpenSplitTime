class AddUpdateReleaseTimesToGatingLocationEvents < ActiveRecord::Migration[8.1]
  def change
    add_column :gating_location_events, :update_release_times, :boolean, default: true, null: false
  end
end
