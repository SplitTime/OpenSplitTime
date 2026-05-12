class AddStatusReasonToSplitTimes < ActiveRecord::Migration[8.1]
  def change
    add_column :split_times, :status_reason, :string
  end
end
