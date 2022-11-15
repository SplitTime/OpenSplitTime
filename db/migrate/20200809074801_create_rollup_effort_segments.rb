class CreateRollupEffortSegments < ActiveRecord::Migration[5.2]
  def change
    create_table :effort_segments, id: false do |t|
      t.integer :course_id
      t.integer :begin_split_id
      t.integer :begin_bitkey
      t.integer :end_split_id
      t.integer :end_bitkey
      t.integer :effort_id
      t.integer :lap
      t.datetime :begin_time
      t.datetime :end_time
      t.integer :elapsed_seconds
      t.integer :data_status

      t.index [:begin_split_id, :begin_bitkey, :end_split_id, :end_bitkey, :effort_id, :lap],
              name: :index_effort_segments_on_unique_attributes,
              unique: true
      t.index :course_id
      t.index :effort_id
      t.index [:begin_split_id, :begin_bitkey, :end_split_id, :end_bitkey],
              name: :index_effort_segments_on_sub_splits
    end
  end
end
