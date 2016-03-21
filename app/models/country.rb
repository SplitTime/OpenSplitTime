# TODO: Consider replacing with Carmen gem

class Country < ActiveRecord::Base
  has_many :participants
  has_many :efforts

  before_save { self.code = code.upcase }

  validates_presence_of :code, :name
  validates_uniqueness_of :code, :name
  validates :code, length: { is: 3 }
end
