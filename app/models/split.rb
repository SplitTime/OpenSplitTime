class Split < ActiveRecord::Base
  enum type: [:start, :finish, :waypoint]

  belongs_to :course
  belongs_to :location
end
