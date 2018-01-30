class RemoveEventsConcealed < ActiveRecord::Migration[5.1]
  def change
    remove_column :events, :concealed, :boolean
    remove_column :events, :available_live, :boolean
    remove_column :events, :auto_live_times, :boolean
    remove_column :events, :organization_id, :integer
  end
end
