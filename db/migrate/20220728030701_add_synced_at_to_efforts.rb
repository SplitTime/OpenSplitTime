class AddSyncedAtToEfforts < ActiveRecord::Migration[7.0]
  def change
    add_column :efforts, :synced_at, :datetime
  end
end
