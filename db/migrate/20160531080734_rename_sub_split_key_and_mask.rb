class RenameSubSplitKeyAndMask < ActiveRecord::Migration
  def change
    rename_column :split_times, :sub_split_key, :sub_split_bitkey
    rename_column :splits, :sub_split_mask, :sub_split_bitmap
  end
end
