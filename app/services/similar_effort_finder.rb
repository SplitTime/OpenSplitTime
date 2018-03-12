# frozen_string_literal: true

class SimilarEffortFinder

  def initialize(args)
    ArgsValidator.validate(params: args,
                           required_alternatives: [:split_time, [:time_point, :time_from_start]],
                           exclusive: [:split_time, :time_point, :time_from_start, :min, :max, :finished],
                           class: self.class)
    @time_point = args[:time_point] || args[:split_time].time_point
    @time_from_start = args[:time_from_start] || args[:split_time].time_from_start
    @minimum_efforts = args[:min] || 20
    @maximum_efforts = args[:max] || 200
    @finished = args[:finished]
  end

  def events
    Event.where(id: efforts.pluck(:event_id).uniq)
  end

  def efforts
    Effort.where(id: effort_ids).limit(maximum_efforts)
  end

  def effort_ids
    @effort_ids ||= selected_effort_times.keys
  end

  private

  attr_reader :time_point, :time_from_start, :minimum_efforts, :maximum_efforts, :finished

  FACTOR_PAIRS = [0.05, 0.10, 0.15, 0.20, 0.25, 0.30].map { |step| [1 - step, 1 + step] }
  POSSIBLE_EFFORT_FACTOR = 2

  def time_ranges
    @time_ranges ||= FACTOR_PAIRS.map { |low, high| [time_from_start * low, time_from_start * high] }
  end

  def selected_effort_times
    time_ranges.each do |low_time, high_time|
      proposed_set = effort_times_in_range(low_time, high_time)
      return proposed_set if proposed_set.size >= minimum_efforts
    end
    effort_times
  end

  def effort_times_in_range(low_time, high_time)
    effort_times.select { |_, time| time.between?(low_time, high_time) }
  end

  def effort_times
    @effort_times ||= scoped_split_times
                          .order('events.start_time desc')
                          .limit(maximum_efforts * POSSIBLE_EFFORT_FACTOR)
                          .pluck(:effort_id, :time_from_start).to_h
  end

  def scoped_split_times
    finished ? ranged_finished_split_times : ranged_split_times
  end

  def ranged_finished_split_times
    ranged_split_times.from_finished_efforts
  end

  def ranged_split_times
    SplitTime.valid_status.visible.at_time_point(time_point).within_time_range(lowest_time, highest_time)
  end

  def lowest_time
    time_ranges.last.first
  end

  def highest_time
    time_ranges.last.last
  end
end
