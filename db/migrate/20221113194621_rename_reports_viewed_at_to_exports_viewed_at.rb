class RenameReportsViewedAtToExportsViewedAt < ActiveRecord::Migration[7.0]
  def change
    rename_column :users, :reports_viewed_at, :exports_viewed_at
  end
end
