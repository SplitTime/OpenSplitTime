# frozen_string_literal: true

# raw_times must be complete with relation ids, lap, and absolute_time
module RawTimes
  class VerifyWithinEffort
    def self.perform(raw_times, effort, options = {})
      new(raw_times, effort, options).perform
    end

    def initialize(raw_times, effort, options = {})
      @raw_times = raw_times
      @effort = effort
      @times_container = options[:times_container] || SegmentTimesContainer.new(calc_model: :stats)
      @errors = []
      validate_setup
    end

    def perform
      set_split_time_exists
      append_split_times
      set_data_status

      raw_times
    end

    private

    attr_reader :raw_times, :effort, :times_container, :errors

    def set_split_time_exists
      raw_times.each do |raw_time|
        existing_split_time = indexed_existing_split_times[raw_time.time_point]
        raw_time.split_time_exists = existing_split_time.present?
        if existing_split_time.present?
          raw_time.split_time_replaceable =
            (existing_split_time.absolute_time - raw_time.absolute_time).abs <= RawTimes::Constants::MATCH_TOLERANCE
        end
      end
    end

    def append_split_times
      raw_times.each do |raw_time|
        next unless raw_time.time_point_complete?
        raw_time.new_split_time = ::SplitTimeFromRawTime.build(raw_time, effort: effort, event: event)
      end
    end

    def set_data_status
      return unless new_split_times.present?

      ::Interactors::SetEffortStatus.perform(effort,
                                             ordered_split_times: combined_split_times,
                                             lap_splits: effort_lap_splits,
                                             times_container: times_container)
      raw_times.select(&:new_split_time).each { |rt| rt.data_status = rt.new_split_time.data_status }
    end

    def combined_split_times
      existing_split_times.each { |st| st.data_status = :confirmed if st.good? }
      indexed_new_split_times = new_split_times.index_by(&:time_point)
      indexed_split_times = indexed_existing_split_times.merge(indexed_new_split_times)
      indexed_split_times.values_at(*effort_time_points).compact
    end

    def indexed_existing_split_times
      @indexed_existing_split_times ||= existing_split_times.index_by(&:time_point)
    end

    def existing_split_times
      @existing_split_times ||= effort.ordered_split_times.map(&:dup)
    end

    def new_split_times
      raw_times.map(&:new_split_time).compact
    end

    def event
      effort.event
    end

    def effort_time_points
      @effort_time_points ||= effort_lap_splits.flat_map(&:time_points)
    end

    def effort_lap_splits
      @effort_lap_splits ||= event.required_lap_splits.presence || event.lap_splits_through(max_raw_time_lap)
    end

    def max_raw_time_lap
      raw_times.max_by(&:lap).lap
    end

    def validate_setup
      raw_times.each do |raw_time|
        raise ArgumentError, "#{raw_time} does not match the provided effort #{effort}" unless raw_time.effort_id == effort.id
      end
    end
  end
end
