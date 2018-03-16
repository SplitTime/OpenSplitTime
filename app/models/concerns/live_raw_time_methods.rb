# frozen_string_literal: true

module LiveRawTimeMethods
  extend ActiveSupport::Concern

  included do
    scope :unconsidered, -> { where(pulled_by: nil).where(split_time: nil) }
    scope :unmatched, -> { where(split_time: nil) }
    validate :absolute_or_entered_time
  end

  def absolute_or_entered_time
    if absolute_time.blank? && entered_time.blank?
      errors.add(:base, 'Either absolute_time or entered_time must be present')
    end
  end

  def matched?
    split_time_id.present?
  end

  def military_time(zone = nil)
    (absolute_time && zone) ? TimeConversion.absolute_to_hms(absolute_time.in_time_zone(zone)) : TimeConversion.file_to_military(entered_time)
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

  def user_full_name
    created_by ? User.find(created_by)&.full_name : '--'
  end

  def pulled_full_name
    pulled_by ? User.find(pulled_by)&.full_name : '--'
  end
end