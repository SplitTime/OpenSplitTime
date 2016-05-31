class RemoveLegacySplits < ActiveRecord::Migration
  def self.up
    raise 'Split_time data is not prepared' if SplitTime.includes(:split).where(splits: {sub_order: 1}).count > 0
    Split.where(sub_order: 1).destroy_all
    remove_column :split_times, :legacy_split_id
    remove_column :splits, :name_extension
    remove_column :splits, :sub_order
    remove_column :splits, :base_split_id
  end

  def self.down
    raise ActiveRecord::IrreversibleMigration, "Can't recover the deleted splits and columns"
  end
end
