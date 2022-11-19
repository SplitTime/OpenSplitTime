class UpdateBestEffortSegmentsToVersion9 < ActiveRecord::Migration[7.0]
  def change
    update_view :best_effort_segments, version: 9, revert_to_version: 8
  end
end
