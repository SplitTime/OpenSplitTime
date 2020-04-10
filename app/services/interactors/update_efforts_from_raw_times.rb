# frozen_string_literal: true

# raw_times should be previously loaded with relation ids etc.
#
# For each raw time having sufficient information, pass it along
# with its effort to RawTimes::VerifyWithinEffort. Raw times are
# passed individually because the decision whether to persist
# a resulting split time is made individually.
#
# This class merely optimizes the effort lookup process;
# the real work is performed by UpdateEffortFromRawTimes and
# by UpsertSplitTimesFromRawTimeRow.
module Interactors
  class UpdateEffortsFromRawTimes
    def self.perform!(event_group, raw_times)
      new(event_group, raw_times).perform!
    end

    def initialize(event_group, raw_times)
      @event_group = event_group
      @raw_times = raw_times
      @times_container = ::SegmentTimesContainer.new(calc_model: :stats)
      @upserted_split_times = []
      @errors = []
    end

    def perform!
      verify_raw_times
      update_raw_times
      update_effort_and_split_times

      ::Interactors::Response.new(errors, '', upserted_split_times: upserted_split_times)
    end

    private

    attr_reader :event_group, :raw_times, :times_container, :upserted_split_times, :errors

    def verify_raw_times
      complete_raw_times.each do |raw_time|
        effort = indexed_efforts[raw_time.effort_id]
        ::RawTimes::VerifyWithinEffort.perform([raw_time], effort, times_container: times_container)
      rescue ArgumentError => e
        errors << e.message
      end
    end

    def update_raw_times
      complete_raw_times.each do |raw_time|
        unless raw_time.save
          errors << resource_error_object(raw_time)
        end
      end
    end

    def update_effort_and_split_times
      upsertable_raw_times.each do |raw_time|
        rtr = ::RawTimeRow.new([raw_time])
        upsert_response = ::Interactors::UpsertSplitTimesFromRawTimeRow.perform!(event_group: event_group, raw_time_row: rtr)
        upsert_response.resources[:upserted_split_times].each { |st| upserted_split_times << st }
        upsert_response.errors.each { |error| errors << error }
      end
    end

    def upsertable_raw_times
      raw_times.reject { |rt| rt.bad? || (rt.split_time_exists? && !rt.split_time_replaceable?) }
    end

    def complete_raw_times
      @complete_raw_times ||= raw_times.select(&:complete?)
    end

    def indexed_efforts
      @indexed_efforts ||= ::Effort.includes(:event).where(id: effort_ids).index_by(&:id)
    end

    def effort_ids
      raw_times.map(&:effort_id).uniq
    end
  end
end
