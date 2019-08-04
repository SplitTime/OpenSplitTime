# frozen_string_literal: true

# raw_time_row.effort should be loaded with {split_times: :split}
# raw_time_row.event should be loaded with :splits

class VerifyRawTimeRow
  def self.perform(raw_time_row, options = {})
    new(raw_time_row, options).perform
  end

  def initialize(raw_time_row, options = {})
    ArgsValidator.validate(subject: raw_time_row, params: options, exclusive: [:times_container], class: self.class)
    @raw_time_row = raw_time_row
    @times_container = options[:times_container] || SegmentTimesContainer.new(calc_model: :stats)
    validate_setup
  end

  def perform
    if errors.empty?
      set_split_time_exists
      append_split_times
      set_data_status
    end
    raw_time_row
  end

  private

  attr_reader :raw_time_row, :times_container
  delegate :raw_times, :effort, :event, :errors, to: :raw_time_row

  def set_split_time_exists
    raw_times.each do |raw_time|
      raw_time.split_time_exists = effort.split_times.any? { |split_time| split_time.time_point == raw_time.time_point }
    end
  end

  def append_split_times
    raw_times.each do |raw_time|
      if time_point_exists?(raw_time)
        raw_time.new_split_time = SplitTimeFromRawTime.build(raw_time, effort: effort, event: event)
      end
    end
  end

  def set_data_status
    return if new_split_times.none?(&:time_from_start)
    Interactors::SetEffortStatus.perform(effort, ordered_split_times: ordered_split_times, lap_splits: effort_lap_splits, times_container: times_container)
    raw_times.select(&:new_split_time).each do |raw_time|
      raw_time.data_status = raw_time.new_split_time.data_status
    end
  end

  def ordered_split_times
    existing_split_times = effort.split_times.map(&:dup)
    indexed_existing_split_times = existing_split_times.each { |st| st.data_status = :confirmed if st.good? }.index_by(&:time_point).freeze
    indexed_new_split_times = new_split_times.select(&:time_from_start).index_by(&:time_point)
    indexed_split_times = indexed_existing_split_times.merge(indexed_new_split_times)
    effort_time_points.map { |time_point| indexed_split_times[time_point] }.compact
  end

  def new_split_times # Do not memoize
    raw_times.map(&:new_split_time).compact
  end

  def time_point_exists?(raw_time)
    split = raw_time_row.split || raw_time.split
    raw_time.lap && raw_time.lap <= (event.maximum_laps || Float::INFINITY) &&
        split&.bitkeys&.include?(raw_time.bitkey)
  end

  def effort_lap_splits
    @effort_lap_splits ||= event.required_lap_splits.presence || event.lap_splits_through(raw_times_laps.first)
  end

  def effort_time_points
    @effort_time_points ||= effort_lap_splits.flat_map(&:time_points)
  end

  def validate_setup
    raw_time_row.errors ||= []

    errors << 'missing raw times' unless raw_times.present?
    errors << 'missing effort' unless effort.present?
    errors << 'missing event' unless event.present?

    if errors.empty?
      errors << 'mismatched bib numbers' if raw_times_bib_numbers.uniq.many? || raw_times_bib_numbers.first.to_i != effort.bib_number
      errors << 'missing lap attribute' unless raw_times_laps.all?
      errors << 'mismatched laps' if raw_times_laps.uniq.many?
      errors << 'lap exceeds event limit' if event.maximum_laps && raw_times_laps.first > event.maximum_laps
      errors << 'mismatched split names' if raw_times_split_names.uniq.many?
      errors << 'invalid split name' unless event_split_names.include?(raw_times_split_names.first.parameterize)
      errors << 'duplicate sub-split kinds' unless raw_times.map(&:bitkey) == raw_times.map(&:bitkey).uniq
    end
  end

  def event_split_names
    @event_split_names ||= event.ordered_splits.map(&:parameterized_base_name)
  end

  def raw_times_bib_numbers
    @raw_times_bib_numbers ||= raw_times.map(&:bib_number)
  end

  def raw_times_laps
    @raw_times_laps ||= raw_times.map(&:lap)
  end

  def raw_times_split_names
    @raw_times_split_names ||= raw_times.map(&:split_name)
  end
end
