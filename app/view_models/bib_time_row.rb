# frozen_string_literal: true

BibTimeRow = Struct.new(:effort_id, :first_name, :last_name, :bib_number, :sortable_bib_number, :raw_times_attributes,
                        :sortable_time, :split_times_attributes, :single_lap, keyword_init: true) do
  include Discrepancy

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

  def problem?
    effort_id.nil? || (single_lap && discrepancy_above_threshold?)
  end

  private

  def guaranteed_string(string_or_nil)
    string_or_nil || '[]'
  end
end
