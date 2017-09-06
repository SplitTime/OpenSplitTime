class LiveTime < ApplicationRecord
  include Auditable

  belongs_to :event
  belongs_to :split
  belongs_to :split_time
  validates_presence_of :event, :split, :bib_number, :bitkey, :source
  validates :bib_number, length: {maximum: 6}, format: {with: /\A[\d\*]+\z/, message: 'may contain only digits and asterisks'}
  validate :absolute_or_entered_time
  validate :course_is_consistent
  validate :split_is_associated
  validate :split_is_consistent

  scope :unconsidered, -> { where(pulled_by: nil).where(split_time: nil) }
  scope :unmatched, -> { where(split_time: nil) }
  scope :with_split_names, -> { joins(:split).select('live_times.*, splits.base_name') }

  def absolute_or_entered_time
    if absolute_time.blank? && entered_time.blank?
      errors.add(:base, 'Either absolute_time or entered_time must be present')
    end
  end

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

  def effort
    return nil if bib_number.include?('*')
    event.efforts.find_by(bib_number: bib_number)
  end

  def effort_full_name
    effort ? effort.full_name : '[Bib not found]'
  end

  def split_base_name
    attributes['base_name'] || split.base_name
  end

  def matched?
    split_time.present?
  end

  def military_time(zone = nil)
    (absolute_time && zone) ? TimeConversion.absolute_to_hms(absolute_time.in_time_zone(zone)) : TimeConversion.file_to_military(entered_time)
  end

  def source_shorthand
    case
    when source.start_with?('ost-remote')
      'OST Remote'
    when source.start_with?('ost-live-entry')
      'Live Data Entry'
    else
      source
    end
  end

  def user_full_name
    created_by ? User.find(created_by)&.full_name : '--'
  end

  def pulled_full_name
    pulled_by ? User.find(pulled_by)&.full_name : '--'
  end
end
