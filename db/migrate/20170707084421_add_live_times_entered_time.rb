class AddLiveTimesEnteredTime < ActiveRecord::Migration
  def change
    add_column :live_times, :entered_time, :string
  end
end
