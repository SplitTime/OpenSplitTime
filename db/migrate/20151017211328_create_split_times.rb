class CreateSplitTimes < ActiveRecord::Migration
  def change
    create_table :split_times do |t|
      t.integer :splittime_id
      t.references :effort, index: true, foreign_key: true
      t.references :split, index: true, foreign_key: true
      t.time :time_from_start
      t.integer :data_status

      t.timestamps null: false
    end
    add_index :split_times, :splittime_id
  end
end
