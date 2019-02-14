class DropLiveTimes < ActiveRecord::Migration[5.2]
  def change
    drop_table :live_times do
    end
  end
end
