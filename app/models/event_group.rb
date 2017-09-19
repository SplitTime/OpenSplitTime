# frozen_string_literal: true

class EventGroup < ApplicationRecord
  include Concealable
  extend FriendlyId
  friendly_id :name, use: :slugged
  strip_attributes collapse_spaces: true
  has_many :events
  belongs_to :organization
  validates_presence_of :name
  validates_uniqueness_of :name, case_sensitive: false

  def to_s
    name
  end

  def ordered_events
    events.sort_by { |event| [-event.start_time.to_i, event.name] }
  end
end
