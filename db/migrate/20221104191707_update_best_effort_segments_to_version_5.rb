class UpdateBestEffortSegmentsToVersion5 < ActiveRecord::Migration[7.0]
  def change
    update_view :best_effort_segments, version: 5, revert_to_version: 4
  end
end
