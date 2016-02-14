class Country < ActiveRecord::Base
  has_many :participants
  has_many :efforts

  validates_presence_of :code, :name
end
