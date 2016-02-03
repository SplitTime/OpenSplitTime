class Participant < ActiveRecord::Base
  validates_presence_of :first_name, :last_name, :gender
  has_many :friendships
  has_many :users, through: :friendships
end
