class AddDataStatusToEfforts < ActiveRecord::Migration
  def change
    add_column :efforts, :data_status, :integer
  end
end
