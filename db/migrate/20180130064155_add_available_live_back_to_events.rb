class AddAvailableLiveBackToEvents < ActiveRecord::Migration[5.1]
  def change
    add_column :events, :available_live, :boolean
  end
end
