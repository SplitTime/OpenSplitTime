module Interactors
  class MatchTimeRecordsToSplitTimes
    include Interactors::Errors

    def self.perform!(time_records:, split_times:, tolerance: 1.minute)
      new(time_records: time_records, split_times: split_times, tolerance: tolerance).perform!
    end

    def initialize(time_records:, split_times:, tolerance: 1.minute)
      raise ArgumentError, "match_time_records_to_split_times must include time_records" unless time_records
      raise ArgumentError, "match_time_records_to_split_times must include split_times" unless split_times

      @time_records = time_records
      @split_times = split_times
      @tolerance = tolerance || 1.minute
      @errors = []
      @resources = { matched: [], unmatched: [] }
    end

    def perform!
      time_records.each { |time_record| match_time_record_to_split_time(time_record) } if errors.blank?
      Interactors::Response.new(errors, message, resources)
    end

    private

    attr_reader :time_records, :split_times, :tolerance, :errors, :resources

    def match_time_record_to_split_time(time_record)
      split_time = matching_split_time(time_record)
      if split_time
        if time_record.update(split_time: split_time)
          matched << time_record
        else
          errors << resource_error_object(time_record)
          unmatched << time_record
        end
      else
        unmatched << time_record
      end
    end

    def matching_split_time(time_record)
      time_record.unmatched? && split_times.find { |split_time| matching_record(split_time, time_record) }
    end

    def matching_record(split_time, time_record)
      (split_time.split_id == time_record.split_id) &&
        (split_time.bitkey == time_record.bitkey) &&
        time_record.matchable_bib_number.present? &&
        (split_time.bib_number == time_record.matchable_bib_number) &&
        (!split_time.stopped_here == !time_record.stopped_here) &&
        (!split_time.pacer == !time_record.with_pacer) &&
        time_matches(split_time, time_record)
    end

    def time_matches(split_time, time_record)
      absolute_time_matches(split_time, time_record) || entered_time_matches(split_time, time_record)
    end

    def absolute_time_matches(split_time, time_record)
      time_record.absolute_time && split_time.absolute_time &&
        (split_time.absolute_time - time_record.absolute_time).abs <= tolerance
    end

    def entered_time_matches(split_time, time_record)
      return false unless time_record.entered_time

      split_parsed = Time.zone.parse(split_time.military_time)
      record_parsed = Time.zone.parse(time_record.entered_time)
      (split_parsed - record_parsed).abs <= tolerance
    end

    def matched
      resources[:matched]
    end

    def unmatched
      resources[:unmatched]
    end

    def message
      "Matched #{matched.size} time records. Did not match #{unmatched.size} time records. "
    end
  end
end
