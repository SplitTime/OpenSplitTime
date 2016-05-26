class CreateSubSplits < ActiveRecord::Migration
  def self.up

    create_table :sub_splits, id: false do |t|
      t.integer :bitkey, null: false
      t.string :kind, null: false
    end

    add_index :sub_splits, :bitkey, unique: true
    add_index :sub_splits, :kind, unique: true

    SubSplit.create(bitkey: 1, kind: 'In')
    # 64.to_s(2) = 1000000; this allows room for new sub_splits that would sort between 'in' and 'out'
    SubSplit.create(bitkey: 64, kind: 'Out')

  end

  def self.down
    drop_table :sub_splits
  end
end
