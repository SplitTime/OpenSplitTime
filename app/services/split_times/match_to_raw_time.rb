# frozen_string_literal: true

module SplitTimes
  class MatchToRawTime
    def self.perform!(split_time, raw_time_id)
      new(split_time, raw_time_id).perform!
    end

    def initialize(split_time, raw_time_id)
      @split_time = split_time
      @raw_time = RawTime.find_by(id: raw_time_id)
      validate_setup if raw_time.present?
    end

    def perform!
      return if split_time.errors.present? || raw_time.nil?

      conform_absolute_time
      match_raw_time
    end

    private

    attr_reader :split_time, :raw_time

    def conform_absolute_time
      if raw_time.absolute_time.present?
        split_time.absolute_time = raw_time.absolute_time
      else
        split_time.military_time = raw_time.military_time
      end
    end

    def match_raw_time
      raw_time.update(split_time_id: split_time.id)
    end

    def validate_setup
      unless split_time.event_group_id == raw_time.event_group_id
        split_time.errors.add(:matching_raw_time_id, "event_group_id #{raw_time.event_group_id} does not match #{split_time.event_group_id}")
      end
    end
  end
end
