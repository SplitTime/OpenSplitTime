class SimilarEffortFinder

  def initialize(args)
    ArgsValidator.validate(params: args,
                           required: [:sub_split, :time_from_start],
                           exclusive: [:sub_split, :time_from_start, :minimum_efforts, :maximum_efforts, :finished],
                           class: self.class)
    @sub_split = args[:sub_split]
    @time_from_start = args[:time_from_start]
    @minimum_efforts = args[:min] || 20
    @maximum_efforts = args[:max] || 200
    @finished = args[:finished]
  end

  def efforts
    @efforts ||= Effort.where(id: effort_ids).limit(maximum_efforts).to_a
  end

  def events
    @events ||= Event.where(id: efforts.map(&:event_id).uniq).to_a
  end

  private

  attr_reader :sub_split, :time_from_start, :minimum_efforts, :maximum_efforts, :finished

  FACTOR_PAIRS = [0.05, 0.10, 0.15, 0.20, 0.25, 0.30].map { |step| [1 - step, 1 + step] }

  def time_ranges
    FACTOR_PAIRS.map { |low_factor, high_factor| [time_from_start * low_factor, time_from_start * high_factor] }
  end

  def effort_ids
    selected_split_times.map(&:effort_id)
  end

  def selected_split_times
    time_ranges.each do |low_time, high_time|
      proposed_set = split_times_in_range(low_time, high_time)
      return proposed_set if proposed_set.count > minimum_efforts
    end
    scoped_split_times
  end

  def split_times_in_range(low_time, high_time)
    scoped_split_times.select { |split_time| split_time.time_from_start.between?(low_time, high_time) }
  end

  def scoped_split_times
    finished ? finished_effort_split_times : possible_split_times
  end

  def finished_effort_split_times
    possible_split_times.select { |split_time| finished_effort_ids.include?(split_time.effort_id) }
  end

  def finished_effort_ids
    @finished_effort_ids ||= Effort.where(id: possible_effort_ids).finished.pluck(:id)
  end

  def possible_effort_ids
    @possible_effort_ids ||= possible_split_times.map(&:effort_id).uniq
  end

  def possible_split_times
    @possible_split_times ||= SplitTime.valid_status
                                  .where(split_id: sub_split.split_id, bitkey: sub_split.bitkey)
                                  .within_time_range(lowest_time, highest_time)
                                  .to_a
  end

  def lowest_time
    time_from_start * FACTOR_PAIRS.last.first
  end

  def highest_time
    time_from_start * FACTOR_PAIRS.last.last
  end
end