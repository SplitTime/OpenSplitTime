class Participant < ActiveRecord::Base
  validates_presence_of :first_name, :last_name, :gender
  has_many :interests
  has_many :users, :through => :interests
end
