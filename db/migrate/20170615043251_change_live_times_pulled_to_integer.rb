class ChangeLiveTimesPulledToInteger < ActiveRecord::Migration
  def self.up
    remove_column :live_times, :pulled
    add_column :live_times, :pulled_by, :integer
    add_column :live_times, :pulled_at, :datetime
  end

  def self.down
    remove_column :live_times, :pulled_at
    remove_column :live_times, :pulled_by
    add_column :live_times, :pulled, :boolean, null: false, default: false
  end
end
