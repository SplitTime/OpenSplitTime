class UpdateBestEffortSegmentsToVersion3 < ActiveRecord::Migration[7.0]
  def change
    update_view :best_effort_segments, version: 3, revert_to_version: 2
  end
end
