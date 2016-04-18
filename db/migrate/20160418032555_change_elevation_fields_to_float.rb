class ChangeElevationFieldsToFloat < ActiveRecord::Migration
  def self.up
    change_column :splits, :vert_gain_from_start, :float
    change_column :splits, :vert_loss_from_start, :float
    change_column :locations, :elevation, :float
  end
  def self.down
    change_column :splits, :vert_gain_from_start, :integer
    change_column :splits, :vert_loss_from_start, :integer
    change_column :locations, :elevation, :integer
  end
end
