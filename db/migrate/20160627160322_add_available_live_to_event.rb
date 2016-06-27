class AddAvailableLiveToEvent < ActiveRecord::Migration
  def change
    add_column :events, :available_live, :boolean, default: false
  end
end
