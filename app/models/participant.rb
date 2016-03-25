class Participant < ActiveRecord::Base
  enum gender: [:male, :female]
  has_many :interests, dependent: :destroy
  has_many :users, :through => :interests

  validates_presence_of :first_name, :last_name, :gender
end
