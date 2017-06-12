class ChangeLiveTimeSourceToString < ActiveRecord::Migration
  def self.up
    remove_column :live_times, :source
    add_column :live_times, :source, :string
    LiveTime.all.each { |lt| lt.update(source: 'ost-internal') }
    change_column_null :live_times, :source, false
  end

  def self.down
    remove_column :live_times, :source
    add_column :live_times, :source, :integer
  end
end
