class CreateEffortSegments < ActiveRecord::Migration[5.2]
  def change
    create_view :effort_segments
  end
end
