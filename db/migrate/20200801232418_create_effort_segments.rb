class CreateEffortSegments < ActiveRecord::Migration[5.2]
  def change
    create_view :effort_segments, materialized: true

    add_index :effort_segments, [:effort_id, :lap, :begin_split_id, :begin_bitkey, :end_split_id, :end_bitkey],
              name: :index_effort_segments_on_unique_fields, unique: true
  end
end
