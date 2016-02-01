class Ownership < ActiveRecord::Base
  validates_presence_of :user_id, :race_id
  belongs_to :user
  belongs_to :race
end
