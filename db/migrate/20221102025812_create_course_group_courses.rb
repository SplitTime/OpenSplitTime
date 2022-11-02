class CreateCourseGroupCourses < ActiveRecord::Migration[7.0]
  def change
    create_table :course_group_courses do |t|
      t.references :course, null: false, foreign_key: true
      t.references :course_group, null: false, foreign_key: true

      t.timestamps
    end
  end
end
