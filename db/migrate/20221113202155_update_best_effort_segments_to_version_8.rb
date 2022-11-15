class UpdateBestEffortSegmentsToVersion8 < ActiveRecord::Migration[7.0]
  def change
    update_view :best_effort_segments, version: 8, revert_to_version: 7
  end
end
