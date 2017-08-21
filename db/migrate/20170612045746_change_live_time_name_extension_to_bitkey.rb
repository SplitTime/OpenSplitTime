class ChangeLiveTimeNameExtensionToBitkey < ActiveRecord::Migration
  def self.up
    add_column :live_times, :bitkey, :integer
    LiveTime.all.each { |live_time| live_time.update(bitkey: SubSplit.bitkey(live_time.split_extension)) }
    remove_column :live_times, :split_extension
  end

  def self.down
    add_column :live_times, :split_extension, :string
    LiveTime.all.each { |live_time| live_time.update(split_extension: SubSplit.kind(live_time.bitkey)) }
    remove_column :live_times, :bitkey
  end
end
