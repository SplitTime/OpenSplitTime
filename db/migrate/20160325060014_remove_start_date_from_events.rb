class RemoveStartDateFromEvents < ActiveRecord::Migration
  def change
    remove_column :events, :start_date, :date
  end
end
