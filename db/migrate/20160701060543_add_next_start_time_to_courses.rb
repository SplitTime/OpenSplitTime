class AddNextStartTimeToCourses < ActiveRecord::Migration
  def change
    add_column :courses, :next_start_time, :datetime
  end
end
