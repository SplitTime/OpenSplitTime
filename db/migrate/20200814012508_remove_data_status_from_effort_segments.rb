class RemoveDataStatusFromEffortSegments < ActiveRecord::Migration[5.2]
  def change
    remove_column :effort_segments, :data_status, :integer
  end
end
