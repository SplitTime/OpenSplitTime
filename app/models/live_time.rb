class LiveTime < ActiveRecord::Base
  enum source: [:internal, :generic_api]
  include Auditable

  belongs_to :event
  belongs_to :split
  belongs_to :split_time
  validates_presence_of :event, :split, :bib_number, :absolute_time, :batch, :recorded_at
  validate :course_is_consistent

  def course_is_consistent
    if event && split && (event.course_id != split.course_id)
      errors.add(:effort_id, 'the event.course_id does not resolve with the split.course_id')
      errors.add(:split_id, 'the event.course_id does not resolve with the split.course_id')
    end
  end

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
