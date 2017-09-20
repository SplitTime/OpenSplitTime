# frozen_string_literal: true

class EventGroup < ApplicationRecord
  include Auditable
  include Concealable
  extend FriendlyId
  friendly_id :name, use: :slugged
  strip_attributes collapse_spaces: true
  has_many :events
  belongs_to :organization
  validates_presence_of :name
  validates_uniqueness_of :name, case_sensitive: false

  after_commit :align_event_booleans # Needed only so long as Event model retains these duplicate attributes

  def to_s
    name
  end

  def ordered_events
    events.sort_by { |event| [-event.start_time.to_i, event.name] }
  end

  def align_event_booleans
    events.each { |event| event.update(available_live: available_live, concealed: concealed, auto_live_times: auto_live_times) }
  end
end
