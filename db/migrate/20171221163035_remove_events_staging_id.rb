class RemoveEventsStagingId < ActiveRecord::Migration[5.1]
  def change
    remove_column :events, :staging_id, :uuid
  end
end
