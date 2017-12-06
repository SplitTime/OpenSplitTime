module Interactors
  class SetSplitTimeStatus

    def self.perform(split_time, options = {})
      new(split_time, options).perform
    end

    def initialize(split_time, options = {})
      ArgsValidator.validate(subject: split_time, subject_class: SplitTime, params: options, exclusive: [:effort, :times_container], class: self.class)
      @split_time = split_time
      @effort = options[:effort] || split_time.effort
      @times_container = options[:times_container] || SegmentTimesContainer.new(calc_model: :stats)
      validate_setup
    end

    def perform
      split_time.data_status = data_status
    end

    private

    attr_reader :split_time, :effort, :times_container
    delegate :ordered_split_times, :lap_splits, to: :effort

    def data_status
      beyond_drop? ? :bad : time_predictor.data_status(segment_time).to_sym
    end

    def time_predictor
      TimePredictor.new(segment: segment,
                        completed_split_time: prior_valid_split_time,
                        lap_splits: lap_splits,
                        times_container: times_container)
    end

    def segment
      Segment.new(begin_point: prior_valid_split_time.time_point,
                  end_point: split_time.time_point,
                  begin_lap_split: begin_lap_split,
                  end_lap_split: end_lap_split)
    end

    def prior_valid_split_time
      subject_index.zero? ? mock_start_split_time : valid_split_times[subject_index - 1]
    end

    def subject_index
      valid_split_times.index(split_time)
    end

    def mock_start_split_time
      @mock_start_split_time ||= SplitTime.new(time_point: ordered_split_times.first.time_point, time_from_start: 0)
    end

    def valid_split_times
      ordered_split_times.select { |st| st.valid_status? | (st == split_time) }
    end

    def begin_lap_split
      indexed_lap_splits[prior_valid_split_time.lap_split_key]
    end

    def end_lap_split
      indexed_lap_splits[split_time.lap_split_key]
    end

    def indexed_lap_splits
      @indexed_lap_splits ||= lap_splits.index_by(&:key)
    end

    def beyond_drop?
      ordered_split_times.included_after?(first_dropped_split_time, split_time)
    end

    def first_dropped_split_time
      ordered_split_times.find(&:stopped_here)
    end

    def segment_time
      split_time.time_from_start - prior_valid_split_time.time_from_start
    end

    def validate_setup
      raise ArgumentError, "split time #{split_time} is not associated with effort #{effort}" unless effort.split_times.include?(split_time)
    end
  end
end
