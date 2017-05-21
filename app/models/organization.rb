class Organization < ActiveRecord::Base

  include Auditable
  include Concealable
  extend FriendlyId
  friendly_id :name, use: :slugged
  strip_attributes collapse_spaces: true
  has_many :events
  has_many :stewardships, dependent: :destroy
  has_many :stewards, through: :stewardships, source: :user

  validates_presence_of :name
  validates_uniqueness_of :name, case_sensitive: false

  def to_s
    slug
  end

  def add_stewardship(user)
    stewards << user
  end

  def remove_stewardship(user)
    stewards.delete(user)
  end

  def should_be_concealed?
    !events.visible.present?
  end
end
