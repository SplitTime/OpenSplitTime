class AddDataStatusToRawTimes < ActiveRecord::Migration[5.1]
  def change
    add_column :raw_times, :data_status, :integer
  end
end
