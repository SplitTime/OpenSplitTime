class AddConcealedToCourses < ActiveRecord::Migration[5.2]
  def change
    add_column :courses, :concealed, :boolean
  end
end
