class AddReportsViewedAtToUsers < ActiveRecord::Migration[7.0]
  def change
    add_column :users, :reports_viewed_at, :datetime
  end
end
