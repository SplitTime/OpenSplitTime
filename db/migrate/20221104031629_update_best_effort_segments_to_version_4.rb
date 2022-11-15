class UpdateBestEffortSegmentsToVersion4 < ActiveRecord::Migration[7.0]
  def change
    update_view :best_effort_segments, version: 4, revert_to_version: 3
  end
end
