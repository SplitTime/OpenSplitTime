class AddDisassociatedToRawTimes < ActiveRecord::Migration[5.2]
  def change
    add_column :raw_times, :disassociated_from_effort, :boolean
  end
end
