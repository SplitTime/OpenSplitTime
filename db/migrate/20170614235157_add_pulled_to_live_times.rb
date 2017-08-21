class AddPulledToLiveTimes < ActiveRecord::Migration
  def change
    add_column :live_times, :pulled, :boolean, null: false, default: false
  end
end
