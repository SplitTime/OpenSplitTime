class CreateSplits < ActiveRecord::Migration
  def change
    create_table :splits do |t|
      t.references :course, index: true, foreign_key: true
      t.references :location, index: true, foreign_key: true
      t.string :name
      t.integer :distance_from_start
      t.integer :order_among_splits_of_same_distance
      t.integer :vert_gain_from_start
      t.integer :vert_loss_from_start
      t.integer :type

      t.timestamps null: false
    end
  end
end
