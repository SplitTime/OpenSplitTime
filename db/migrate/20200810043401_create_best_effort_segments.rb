class CreateBestEffortSegments < ActiveRecord::Migration[5.2]
  def change
    create_view :best_effort_segments
  end
end
