class CreateCourses < ActiveRecord::Migration
  def change
    create_table :courses do |t|
      t.integer :course_id
      t.string :course_name
      t.integer :start_elevation
      t.string :start_location_name
      t.string :end_location_name

      t.timestamps null: false
    end
  end
end
