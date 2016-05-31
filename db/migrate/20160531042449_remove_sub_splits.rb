class RemoveSubSplits < ActiveRecord::Migration

  def self.up
    remove_foreign_key :split_times, :sub_split
    drop_table :sub_splits
    rename_column :split_times, :sub_split_id, :sub_split_key
  end

  def self.down

    rename_column :split_times, :sub_split_key, :sub_split_id
    create_table :sub_splits, id: false do |t|
      t.integer :key, null: false
      t.string :kind, null: false
    end

    add_index :sub_splits, :key, unique: true
    add_index :sub_splits, :kind, unique: true

    SubSplit.create(key: 1, kind: 'In')
    # 64.to_s(2) = 1000000; this allows room for new sub_splits that would sort between 'in' and 'out'
    SubSplit.create(key: 64, kind: 'Out')

  end

end