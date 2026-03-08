class AddIndexToEffortSegmentsForMinMaxQueries < ActiveRecord::Migration[8.0]
  disable_ddl_transaction!

  def change
    add_index :effort_segments,
              [:begin_split_id, :end_split_id, :elapsed_seconds],
              name: "index_effort_segments_on_splits_and_elapsed",
              algorithm: :concurrently
  end
end
