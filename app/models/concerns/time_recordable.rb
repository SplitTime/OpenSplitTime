module TimeRecordable
  extend ActiveSupport::Concern

  included do
    scope :unreviewed, -> { where(reviewed_by: nil).where(split_time: nil) }
    scope :unmatched, -> { where(split_time: nil) }
    validate :absolute_or_entered_time
  end

  def absolute_or_entered_time
    return unless absolute_time.blank? && entered_time.blank?

    errors.add(:base, "Either absolute_time or entered_time must be present")
  end

  def creator_full_name
    creator&.full_name || "--"
  end

  def reviewer_full_name
    reviewer&.full_name || "--"
  end

  def effort_full_name
    effort&.full_name || "[Bib not found]"
  end

  def split_base_name
    split&.base_name || "[Split not found]"
  end

  def matched?
    split_time_id.present?
  end

  def unmatched?
    !matched?
  end

  def military_time(zone = nil)
    zone ||= home_time_zone

    if absolute_time && zone
      TimeConversion.absolute_to_hms(absolute_time.in_time_zone(zone))
    else
      TimeConversion.user_entered_to_military(entered_time)
    end
  end

  def source_text
    if source.start_with?("ost-remote")
      "OSTR (#{source.last(4)})"
    elsif source.start_with?("ost-remote-2")
      "OSTR2 (#{source.last(4)})"
    elsif source.start_with?("ost-live-entry")
      "Live Entry (#{created_by})"
    else
      source
    end
  end
end
