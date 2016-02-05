class CreateSplits < ActiveRecord::Migration
  def change
    create_table :splits do |t|
      t.references :course, index: true, foreign_key: true
      t.references :location, index: true, foreign_key: true
      t.string :name
      t.integer :distance_from_start     # stored in meters?; primary sort field for split ordering within a course
      t.integer :sub_order, default: 0   # secondary sort when multiple splits have the same distance_from_start
      t.integer :vert_gain_from_start    # stored in meters?
      t.integer :vert_loss_from_start    # stored in meters?
      t.integer :kind

      t.timestamps null: false
    end
  end
end
