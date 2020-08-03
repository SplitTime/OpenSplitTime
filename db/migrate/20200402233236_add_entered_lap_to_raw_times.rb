class AddEnteredLapToRawTimes < ActiveRecord::Migration[5.2]
  def change
    add_column :raw_times, :entered_lap, :integer
  end
end
