class Race < ActiveRecord::Base
  has_many :events
  has_many :ownerships
  has_many :users, :through => :ownerships

  validates_presence_of :name
  validates_uniqueness_of :name
end
