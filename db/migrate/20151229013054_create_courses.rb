class CreateCourses < ActiveRecord::Migration
  def change
    create_table :courses do |t|
      t.string :name
      t.references :start_location
      t.references :end_location
      t.timestamps null: false
    end
  end
end
