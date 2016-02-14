class CreateSplits < ActiveRecord::Migration
  def change
    create_table :splits do |t|
      t.references :course, index: true, foreign_key: true, :null => false
      t.references :location, index: true, foreign_key: true, :null => false
      t.string :name, :null => false, limit: 64
      t.integer :distance_from_start, :null => false     # stored in meters?; primary sort field for split ordering within a course
      t.integer :sub_order, default: 0, :null => false   # secondary sort when multiple splits have the same distance_from_start
      t.integer :vert_gain_from_start    # stored in meters?
      t.integer :vert_loss_from_start    # stored in meters?
      t.integer :kind, :null => false

      t.timestamps null: false
      t.authorstamps :integer
    end
  end
end
