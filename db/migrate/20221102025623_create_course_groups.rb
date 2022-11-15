class CreateCourseGroups < ActiveRecord::Migration[7.0]
  def change
    create_table :course_groups do |t|
      t.references :organization, null: false, foreign_key: true
      t.string :name
      t.string :slug

      t.timestamps
    end
  end
end
