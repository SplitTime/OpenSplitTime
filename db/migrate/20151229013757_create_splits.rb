class CreateSplits < ActiveRecord::Migration
  def change
    create_table :splits do |t|
      t.references :course, index: true, foreign_key: true
      t.string :name
      t.integer :distance
      t.integer :order
      t.integer :vert_gain
      t.integer :vert_loss

      t.timestamps null: false
    end
  end
end
