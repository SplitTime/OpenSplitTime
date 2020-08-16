# frozen_string_literal: true

module TimeRecordable
  extend ActiveSupport::Concern

  included do
    scope :unreviewed, -> { where(reviewed_by: nil).where(split_time: nil) }
    scope :unmatched, -> { where(split_time: nil) }
    validate :absolute_or_entered_time
  end

  attr_writer :creator, :reviewer

  def absolute_or_entered_time
    if absolute_time.blank? && entered_time.blank?
      errors.add(:base, 'Either absolute_time or entered_time must be present')
    end
  end

  def creator_full_name
    creator&.full_name || '--'
  end

  def reviewer_full_name
    reviewer&.full_name || '--'
  end

  def effort_full_name
    effort&.full_name || '[Bib not found]'
  end

  def split_base_name
    split&.base_name || '[Split not found]'
  end

  def matched?
    split_time_id.present?
  end

  def unmatched?
    !matched?
  end

  def military_time(zone = nil)
    absolute_time && zone ?
        TimeConversion.absolute_to_hms(absolute_time.in_time_zone(zone)) :
        TimeConversion.user_entered_to_military(entered_time)
  end

  def source_text
    case
    when source.start_with?('ost-remote')
      "OSTR (#{source.last(4)})"
    when source.start_with?('ost-live-entry')
      "Live Entry (#{created_by})"
    else
      source
    end
  end

  def creator
    return @creator if defined?(@creator)
    @creator = User.find_by(id: created_by) if created_by
  end

  def reviewer
    return @reviewer if defined?(@reviewer)
    @reviewer = User.find_by(id: reviewed_by) if reviewed_by
  end
end
