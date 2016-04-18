class Race < ActiveRecord::Base
  include Auditable
  has_many :events
  has_many :ownerships, dependent: :destroy
  has_many :users, :through => :ownerships

  validates_presence_of :name
  validates_uniqueness_of :name, case_sensitive: false
end
