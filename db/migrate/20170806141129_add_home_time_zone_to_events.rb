class AddHomeTimeZoneToEvents < ActiveRecord::Migration
  def up
    add_column :events, :home_time_zone, :string
    Event.all.each { |event| event.update(home_time_zone: 'Mountain Time (US & Canada)') }
    change_column_null :events, :home_time_zone, false
  end

  def down
    remove_column :events, :home_time_zone
  end
end
