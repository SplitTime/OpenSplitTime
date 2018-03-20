# frozen_string_literal: true

module Interactors
  class MatchTimeRecords
    include Interactors::Errors

    def self.perform!(args)
      new(args).perform!
    end

    def initialize(args)
      ArgsValidator.validate(params: args,
                             required: [:time_records, :split_times],
                             exclusive: [:time_records, :split_times, :tolerance],
                             class: self.class)
      @time_records = args[:time_records]
      @split_times = args[:split_times]
      @tolerance = args[:tolerance] || 1.minute
      @errors = []
      @resources = {matched: [], unmatched: []}
    end

    def perform!
      unless errors.present?
        time_records.each { |lt| match_time_record_to_split_time(lt) }
      end
      Interactors::Response.new(errors, message, resources)
    end

    private

    attr_reader :time_records, :split_times, :tolerance, :errors, :resources

    def match_time_record_to_split_time(time_record)
      split_time = matching_split_time(time_record)
      if split_time
        time_record.update(split_time: split_time)
        matched << time_record
      else
        unmatched << time_record
      end
    end

    def matching_split_time(time_record)
      !time_record.matched? && split_times.find { |split_time| matching_record(split_time, time_record) }
    end

    def matching_record(split_time, time_record)
      (split_time.split_id == time_record.split_id) &&
          (split_time.bitkey == time_record.bitkey) &&
          (split_time.bib_number.to_s == time_record.bib_number) &&
          ((time_record.stopped_here || false) == (split_time.stopped_here || false)) &&
          ((time_record.with_pacer || false) == (split_time.pacer || false)) &&
          time_matches(split_time, time_record)
    end

    def time_matches(split_time, time_record)
      (time_record.absolute_time && (split_time.day_and_time - time_record.absolute_time).abs <= tolerance) ||
          (time_record.entered_time && (Time.parse(split_time.military_time) - Time.parse(time_record.entered_time)).abs <= tolerance)
    end

    def matched
      resources[:matched]
    end

    def unmatched
      resources[:unmatched]
    end

    def message
      "Matched #{matched.size} live times. Did not match #{unmatched.size} live times. "
    end
  end
end
