class Course < ActiveRecord::Base

  belongs_to :start_location, :class_name => "Location"
  belongs_to :end_location, :class_name => "Location"
end
