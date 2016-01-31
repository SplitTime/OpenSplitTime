class Race < ActiveRecord::Base
  has_many :events
  has_many :ownerships
  has_many :users, :through => :ownerships
end
