class Split < ActiveRecord::Base
  enum type: [:start, :finish, :foot, :aid]

  belongs_to :course
  belongs_to :location
end
