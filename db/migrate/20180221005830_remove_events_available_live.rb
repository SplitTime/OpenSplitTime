class RemoveEventsAvailableLive < ActiveRecord::Migration[5.1]
  def change
    remove_column :events, :available_live, :boolean
  end
end
