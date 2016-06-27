class Race < ActiveRecord::Base
  include Auditable
  strip_attributes collapse_spaces: true
  has_many :events
  has_many :stewardships, dependent: :destroy
  has_many :stewards, through: :stewardships, source: :user

  validates_presence_of :name
  validates_uniqueness_of :name, case_sensitive: false
end
