class AddLapsRequiredToEvents < ActiveRecord::Migration
  def change
    add_column :events, :laps_required, :integer
    reversible do |direction|
      direction.up { Event.update_all(laps_required: 1) }
    end
  end
end