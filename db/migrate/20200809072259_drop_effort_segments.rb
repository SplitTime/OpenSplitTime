class DropEffortSegments < ActiveRecord::Migration[5.2]
  def change
    drop_view :effort_segments
  end
end
