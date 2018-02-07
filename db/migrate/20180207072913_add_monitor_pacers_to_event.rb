class AddMonitorPacersToEvent < ActiveRecord::Migration[5.1]
  def change
    add_column :events, :monitor_pacers, :boolean, default: false
  end
end
