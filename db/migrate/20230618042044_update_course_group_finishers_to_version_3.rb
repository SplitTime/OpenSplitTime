class UpdateCourseGroupFinishersToVersion3 < ActiveRecord::Migration[7.0]
  def change
  
    update_view :course_group_finishers, version: 3, revert_to_version: 2
  end
end
