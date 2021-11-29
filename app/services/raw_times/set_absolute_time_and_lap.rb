# frozen_string_literal: true

module RawTimes
  class SetAbsoluteTimeAndLap
    MILITARY_TIME_REGEX = /\A\d{1,2}:\d{2}(:\d{2})?\z/

    def self.perform(event_group, raw_times)
      new(event_group, raw_times).perform
    end

    def initialize(event_group, raw_times)
      @event_group = event_group
      @raw_times = ::RawTime.where(id: raw_times).with_relation_ids
      validate_setup
    end

    def perform
      raw_times.each do |raw_time|
        set_lap_simple(raw_time)
        set_entered_from_absolute_time(raw_time) if raw_time.absolute_time.present? # See note below
        set_absolute_from_entered_time(raw_time) unless raw_time.absolute_time.present?
        set_lap_using_time(raw_time) unless raw_time.lap.present?
      end

      raw_times
    end

    private

    attr_reader :event_group, :raw_times

    def set_lap_simple(raw_time)
      if raw_time.entered_lap
        raw_time.lap = raw_time.entered_lap
      elsif single_lap_event_group? || single_lap_event?(raw_time)
        raw_time.lap = 1
      end
    end

    # Versions of OST Remote prior to July 2020 set absolute_time directly,
    # making it necessary to copy absolute_time to entered_time
    # if absolute_time exists.
    #
    # This method can be removed once OST Remote sets entered_time
    # instead of absolute_time (and there has been plenty of time for
    # users to upgrade). January 2021 should be about right.
    #
    # See also the RowifyRawTimes class.
    #
    def set_entered_from_absolute_time(raw_time)
      raw_time.entered_time = raw_time.absolute_time
    end

    def set_absolute_from_entered_time(raw_time)
      if raw_time.entered_time =~ MILITARY_TIME_REGEX
        raw_time.absolute_time = calculated_absolute_time(raw_time)
      else
        raw_time.absolute_time = raw_time.entered_time.in_time_zone(event_group.home_time_zone)
      end
    end

    def set_lap_using_time(raw_time)
      if raw_time.absolute_time
        raw_time.lap = expected_lap(raw_time, :absolute_time_local, raw_time.absolute_time)
      elsif raw_time.military_time
        raw_time.lap = expected_lap(raw_time, :military_time, raw_time.military_time)
      else
        raw_time.lap = nil
      end
    end

    def expected_lap(raw_time, subject_attribute, subject_value)
      ::FindExpectedLap.perform(effort: indexed_efforts[raw_time.effort_id],
                                subject_attribute: subject_attribute,
                                subject_value: subject_value,
                                split_id: raw_time.split_id,
                                bitkey: raw_time.bitkey)
    end

    def calculated_absolute_time(raw_time)
      return unless raw_time.effort_id && raw_time.split_id

      ::IntendedTimeCalculator.absolute_time_local(military_time: raw_time.entered_time,
                                                   effort: indexed_efforts[raw_time.effort_id],
                                                   time_point: raw_time.time_point)
    end

    def single_lap_event_group?
      @single_lap_event_group ||= event_group.single_lap?
    end

    def single_lap_event?(raw_time)
      indexed_events[raw_time.event_id]&.single_lap?
    end

    def indexed_events
      @indexed_events ||= event_group.events.index_by(&:id)
    end

    def indexed_efforts
      @indexed_efforts ||= ::Effort.where(id: raw_times.map(&:effort_id)).index_by(&:id)
    end

    def validate_setup
      raise ArgumentError, 'All raw_times must match the provided event_group' unless raw_times.all? { |rt| rt.event_group_id == event_group.id }
    end
  end
end
