class UpdateBestEffortSegmentsToVersion10 < ActiveRecord::Migration[7.0]
  def change
    update_view :best_effort_segments, version: 10, revert_to_version: 9
  end
end
