class Race < ActiveRecord::Base
  validates_presence_of :name
  validates_uniqueness_of :name
  has_many :events
  has_many :ownerships
  has_many :users, :through => :ownerships
end
