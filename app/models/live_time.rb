# frozen_string_literal: true

class LiveTime < ApplicationRecord
  include Auditable
  include TimeRecordable

  belongs_to :event
  belongs_to :split
  belongs_to :split_time
  validates_presence_of :event, :split, :bib_number, :bitkey, :source
  validates :bib_number, length: {maximum: 6}, format: {with: /\A[\d\*]+\z/, message: 'may contain only digits and asterisks'}
  validates_uniqueness_of :absolute_time, scope: [:event_id, :split_id, :bitkey, :bib_number, :source, :with_pacer, :stopped_here, :remarks],
                          message: 'is an exact duplicate of an existing live time',
                          if: Proc.new { |live_time| live_time.absolute_time.present? }
  validates_uniqueness_of :entered_time, scope: [:event_id, :split_id, :bitkey, :bib_number, :source, :with_pacer, :stopped_here, :remarks],
                          message: 'is an exact duplicate of an existing live time',
                          if: Proc.new { |live_time| live_time.entered_time.present? }
  validate :course_is_consistent
  validate :split_is_associated
  validate :split_is_consistent

  delegate :distance_from_start, to: :split

  def course_is_consistent
    if event && split && (event.course_id != split.course_id)
      errors.add(:split_id, 'the event.course_id does not resolve with the split.course_id')
    end
  end

  def split_is_associated
    if event && split && event.splits.exclude?(split)
      errors.add(:split_id, 'the split is not associated with the event')
    end
  end

  def split_is_consistent
    if split && split_time && (split != split_time.split)
      errors.add(:split_time_id, 'the split_id is not the same as the split_time.split_id')
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

  def sub_split_kind
    SubSplit.kind(bitkey)
  end

  def sub_split_kind=(sub_split_kind)
    self.bitkey = SubSplit.bitkey(sub_split_kind.to_s)
  end

  def sub_split
    {split_id => bitkey}
  end

  def effort
    return nil if bib_number.include?('*')
    event.efforts.find { |effort| effort.bib_number.to_s == bib_number }
  end

  def effort_full_name
    effort&.full_name || '[Bib not found]'
  end

  def split_base_name
    split&.base_name || '[Split not found]'
  end

  def aid_station
    event.aid_stations.find { |aid_station| aid_station.split_id == split_id }
  end
end
