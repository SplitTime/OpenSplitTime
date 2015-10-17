class CreateSplits < ActiveRecord::Migration
  def change
    create_table :splits do |t|
      t.integer :split_id
      t.string :split_name
      t.references :course, index: true, foreign_key: true
      t.integer :split_order
      t.integer :vert_gain_from_start
      t.integer :vert_loss_from_start

      t.timestamps null: false
    end
    add_index :splits, :split_id
  end
end
