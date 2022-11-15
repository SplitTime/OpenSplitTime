class UpdateBestEffortSegmentsToVersion6 < ActiveRecord::Migration[7.0]
  def change
    update_view :best_effort_segments, version: 6, revert_to_version: 5
  end
end
