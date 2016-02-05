class CreateSplitTimes < ActiveRecord::Migration
  def change
    create_table :split_times do |t|
      t.references :effort, index: true, foreign_key: true
      t.references :split, index: true, foreign_key: true
      t.float :time_from_start    # stored as seconds.milliseconds elapsed
      t.integer :data_status

      t.timestamps null: false
    end
  end
end
