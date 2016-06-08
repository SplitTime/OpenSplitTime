class CreateSubSplits < ActiveRecord::Migration
  def self.up

    create_table :sub_splits, id: false do |t|
      t.integer :bitkey, null: false
      t.string :kind, null: false
    end

    add_index :sub_splits, :bitkey, unique: true
    add_index :sub_splits, :kind, unique: true

  end

  def self.down
    drop_table :sub_splits
  end
end
