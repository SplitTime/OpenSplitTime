class AddLapToSplitTimes < ActiveRecord::Migration
  def change
    add_column :split_times, :lap, :integer
    reversible do |direction|
      direction.up { SplitTime.update_all(lap: 1) }
    end
  end
end