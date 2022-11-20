class CreateCourseGroupFinishers < ActiveRecord::Migration[7.0]
  def change
    create_view :course_group_finishers
  end
end
