# frozen_string_literal: true

module TimeRecordable
  extend ActiveSupport::Concern

  included do
    scope :unconsidered, -> { where(pulled_by: nil).where(split_time: nil) }
    scope :unmatched, -> { where(split_time: nil) }
    validate :absolute_or_entered_time
  end

  attr_writer :creator, :puller

  def absolute_or_entered_time
    if absolute_time.blank? && entered_time.blank?
      errors.add(:base, 'Either absolute_time or entered_time must be present')
    end
  end

  def creator_full_name
    creator&.full_name || '--'
  end

  def puller_full_name
    puller&.full_name || '--'
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

  def creator
    return @creator if defined?(@creator)
    User.find_by(id: created_by) if created_by
  end

  def puller
    return @puller if defined?(@puller)
    User.find_by(id: pulled_by) if pulled_by
  end

  private

  def create_sortable_bib_number
    self.sortable_bib_number = bib_number&.gsub(/\D/, '0').to_i
  end
end
