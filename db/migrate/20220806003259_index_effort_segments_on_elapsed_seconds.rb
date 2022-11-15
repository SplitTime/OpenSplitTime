class IndexEffortSegmentsOnElapsedSeconds < ActiveRecord::Migration[7.0]
  disable_ddl_transaction!

  def change
    add_index :effort_segments, :elapsed_seconds, algorithm: :concurrently
  end
end
