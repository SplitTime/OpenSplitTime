class AddIndexToEventsStagingId < ActiveRecord::Migration
  def change
    add_index :events, :staging_id, unique: true
  end
end