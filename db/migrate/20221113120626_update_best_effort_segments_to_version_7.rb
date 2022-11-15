class UpdateBestEffortSegmentsToVersion7 < ActiveRecord::Migration[7.0]
  def change
    update_view :best_effort_segments, version: 7, revert_to_version: 6
  end
end
