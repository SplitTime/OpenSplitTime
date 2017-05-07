class LiveTime < ActiveRecord::Base
  enum source: [:internal, :generic_api]
  include Auditable

  belongs_to :event
  belongs_to :split
  validates_presence_of :event, :split, :bib_number, :absolute_time, :batch, :recorded_at

  def event_slug
    event.slug
  end

  def event_slug=(slug)
    self.event = Event.find_by(slug: slug)
  end

  def split_slug
    split.slug
  end

  def split_slug=(slug)
    self.split = Split.find_by(slug: slug)
  end
end
