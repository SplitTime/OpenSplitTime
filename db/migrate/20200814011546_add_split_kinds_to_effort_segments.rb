class AddSplitKindsToEffortSegments < ActiveRecord::Migration[5.2]
  def change
    add_column :effort_segments, :begin_split_kind, :integer
    add_column :effort_segments, :end_split_kind, :integer
  end
end
