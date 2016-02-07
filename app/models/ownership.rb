class Ownership < ActiveRecord::Base
  belongs_to :user
  belongs_to :race

  validates_presence_of :user_id, :race_id
end
