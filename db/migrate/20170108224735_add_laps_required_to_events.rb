class AddLapsRequiredToEvents < ActiveRecord::Migration
  def change
    add_column :events, :laps_required, :integer, default: 1
  end
end