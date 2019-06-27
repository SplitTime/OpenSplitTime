# frozen_string_literal: true

BibTimeRow = Struct.new(:effort_id, :first_name, :last_name, :bib_number, :sortable_bib_number, :raw_times_attributes,
                        :sortable_time, :split_times_attributes, :single_lap, keyword_init: true) do

  DISCREPANCY_THRESHOLD = 1.minute

  def full_name
    "#{first_name} #{last_name}".strip.presence || '[Bib not found]'
  end

  def grouped_raw_times
    raw_times.group_by(&:source_text)
  end

  def raw_times
    @raw_times ||= JSON.parse(guaranteed_string(raw_times_attributes)).map { |row| RawTimeData.new(row) }
  end

  def split_times
    @split_times ||= JSON.parse(guaranteed_string(split_times_attributes)).map { |row| SplitTimeData.new(row) }
  end

  def largest_discrepancy
    adjusted_times = times_in_seconds.map { |seconds| (seconds - times_in_seconds.first) > 12.hours ? (seconds - 24.hours).to_i : seconds }.sort
    (adjusted_times.last - adjusted_times.first).to_i
  end

  def problem?
    effort_id.nil? || (single_lap && largest_discrepancy > DISCREPANCY_THRESHOLD)
  end

  private

  def times_in_seconds
    @times_in_seconds ||= joined_military_times.map { |military_time| TimeConversion.hms_to_seconds(military_time) }
  end

  def joined_military_times
    (split_times.map(&:military_time) | raw_times.map(&:military_time)).compact.sort
  end

  def guaranteed_string(string_or_nil)
    string_or_nil || '[]'
  end
end
