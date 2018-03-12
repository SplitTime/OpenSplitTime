# frozen_string_literal: true

module Interactors
  class SetEffortStatus

    # This class expects to be given an effort loaded with split_times: :splits, or in the alternative, it expects
    # :ordered_split_times and :lap_splits to be provided in tne options hash.

    def self.perform(effort, options = {})
      new(effort, options).perform
    end

    def initialize(effort, options = {})
      ArgsValidator.validate(subject: effort, subject_class: Effort, params: options,
                             exclusive: [:ordered_split_times, :lap_splits, :times_container], class: self)
      @effort = effort
      @ordered_split_times = options[:ordered_split_times] || effort.ordered_split_times.reject(&:destroyed?)
      @lap_splits = options[:lap_splits] || effort.lap_splits
      @times_container = options[:times_container] || SegmentTimesContainer.new(calc_model: :stats)
    end

    def perform
      unconfirmed_split_times.each { |split_time| set_split_time_status(split_time) }
      set_effort_status
      Interactors::Response.new([], '', changed_resources)
    end

    private

    attr_reader :effort, :ordered_split_times, :lap_splits, :times_container
    attr_accessor :subject_split_time, :valid_split_times, :subject_index, :prior_valid_split_time,
                  :subject_begin_lap_split, :subject_end_lap_split, :subject_segment, :subject_segment_time

    def set_split_time_status(split_time)
      set_subject_attributes(split_time)
      subject_split_time.data_status = beyond_drop? ? 'bad' : time_predictor.data_status(subject_segment_time)
    end

    def set_effort_status
      effort.data_status = ordered_split_times.map(&:data_status_numeric).push(Effort.data_statuses[:good]).compact.min
    end

    def set_subject_attributes(split_time)
      self.subject_split_time = split_time
      self.valid_split_times = ordered_split_times.select { |st| st.valid_status? | (st == subject_split_time) }
      self.prior_valid_split_time = valid_split_times.elements_before(subject_split_time).last || mock_start_split_time
      self.subject_begin_lap_split = indexed_lap_splits[prior_valid_split_time.lap_split_key]
      self.subject_end_lap_split = indexed_lap_splits[subject_split_time.lap_split_key]
      self.subject_segment = Segment.new(begin_point: prior_valid_split_time.time_point,
                                         end_point: subject_split_time.time_point,
                                         begin_lap_split: subject_begin_lap_split,
                                         end_lap_split: subject_end_lap_split)
      self.subject_segment_time = subject_split_time.time_from_start - prior_valid_split_time.time_from_start
    end

    def beyond_drop?
      ordered_split_times.included_after?(first_dropped_split_time, subject_split_time)
    end

    def time_predictor
      TimePredictor.new(segment: subject_segment,
                        completed_split_time: prior_valid_split_time,
                        lap_splits: lap_splits,
                        times_container: times_container)
    end

    def mock_start_split_time
      @mock_start_split_time ||= SplitTime.new(time_point: start_time_point, time_from_start: 0)
    end

    def start_time_point
      @start_time_point ||= TimePoint.new(1, lap_splits.first.split_id, SubSplit::IN_BITKEY)
    end

    def first_dropped_split_time
      ordered_split_times.find(&:stopped_here)
    end

    def indexed_lap_splits
      @indexed_lap_splits ||= lap_splits.index_by(&:key)
    end

    def changed_resources
      changed_effort + changed_split_times
    end

    def changed_effort
      [effort].select(&:changed?)
    end

    def changed_split_times
      ordered_split_times.select(&:changed?)
    end

    def unconfirmed_split_times
      @unconfirmed_split_times ||= ordered_split_times.reject(&:confirmed?)
    end
  end
end
