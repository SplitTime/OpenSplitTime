class RenameRawTimesPulledByPulledAt < ActiveRecord::Migration[5.2]
  def change
    rename_column :raw_times, :pulled_at, :reviewed_at
    rename_column :raw_times, :pulled_by, :reviewed_by
  end
end
