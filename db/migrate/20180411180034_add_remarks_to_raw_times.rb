class AddRemarksToRawTimes < ActiveRecord::Migration[5.1]
  def change
    add_column :raw_times, :remarks, :string
  end
end
