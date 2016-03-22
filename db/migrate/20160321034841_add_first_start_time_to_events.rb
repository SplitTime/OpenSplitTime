class AddFirstStartTimeToEvents < ActiveRecord::Migration
  def change
    add_column :events, :first_start_time, :datetime
  end
end
