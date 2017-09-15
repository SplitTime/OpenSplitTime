# frozen_string_literal: true

class EventGroup < ApplicationRecord
  extend FriendlyId
  friendly_id :name, use: :slugged
  has_many :events
  belongs_to :organization
  validates_presence_of :name
  validates_uniqueness_of :name, case_sensitive: false

  def to_s
    name
  end
end
