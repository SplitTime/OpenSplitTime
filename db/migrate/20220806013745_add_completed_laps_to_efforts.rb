class AddCompletedLapsToEfforts < ActiveRecord::Migration[7.0]
  def change
    add_column :efforts, :completed_laps, :integer
  end
end
