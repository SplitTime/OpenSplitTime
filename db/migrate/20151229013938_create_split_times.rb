class CreateSplitTimes < ActiveRecord::Migration
  def change
    create_table :split_times do |t|
      t.references :effort, index: true, foreign_key: true, :null => false
      t.references :split, index: true, foreign_key: true, :null => false
      t.float :time_from_start, :null => false    # stored as seconds.milliseconds elapsed
      t.integer :data_status

      t.timestamps null: false
      t.integer :created_by, null: false
      t.integer :updated_by, null: false
    end
  end
end
