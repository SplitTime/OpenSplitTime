class AddDroppedLapToEfforts < ActiveRecord::Migration
  def change
    add_column :efforts, :dropped_lap, :integer
    reversible do |direction|
      direction.up { Effort.where.not(dropped_split_id: nil).update_all(dropped_lap: 1) }
    end
  end
end