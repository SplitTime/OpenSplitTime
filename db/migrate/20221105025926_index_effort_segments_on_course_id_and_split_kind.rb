class IndexEffortSegmentsOnCourseIdAndSplitKind < ActiveRecord::Migration[7.0]
  def change
    add_index :effort_segments, [:course_id, :begin_split_kind, :end_split_kind], name: :index_effort_segments_by_course_id_and_split_kind
  end
end
