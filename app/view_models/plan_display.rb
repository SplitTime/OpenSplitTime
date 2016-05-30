class PlanDisplay
  attr_reader :course, :expected_time, :relevant_events, :relevant_efforts, :split_rows

  MAX_EVENTS = 5

  def initialize(course, params)
    @course = course
    @event = course.events.most_recent
    @expected_time = expected_time_from_param(params[:expected_time])
    if @event && @expected_time
      @relevant_events = course.events.recent(MAX_EVENTS)
      @relevant_efforts = course.relevant_efforts(expected_time, MAX_EVENTS).to_a
      @splits = event.ordered_splits.to_a
      @split_times = create_plan_split_times
      @start_time = params[:start_time] ? params[:start_time].to_datetime : @event.start_time
      @split_rows = create_split_rows
    end
  end

  def total_time_in_aid
    split_rows.sum { |unicorn| unicorn.time_in_aid }
  end

  def relevant_efforts_count
    relevant_efforts.count
  end

  def event_years_analyzed
    relevant_events.pluck(:start_time).sort.map(&:year)
  end

  private

  attr_reader :event, :splits, :split_times, :start_time

  def expected_time_from_param(expected_time_param)
    return nil if expected_time_param.blank?
    # TODO: do regex test here
    h = expected_time_param.split(":")[0].to_i
    m = expected_time_param.split(":")[1].to_i
    ((h * 60 * 60) + (m * 60))
  end

  def create_plan_split_times
    plan_times = calculate_plan_times
    result = []
    splits.each do |split|
      split.sub_split_keys.each do |key|
        split_time = SplitTime.new(split: split, sub_split_id: key, time_from_start: plan_times[{split.id => key}])
        result << split_time
      end
    end
    result.index_by(&:key_hash)
  end

  def calculate_plan_times # Hash of {{split.id => key} => plan_time_from_start}
    average_time_hash = {}
    splits.each do |split|
      split.sub_split_keys.each do |key|
        sub_split_average = split.average_time(key, relevant_efforts)
        average_time_hash[{split.id => key}] = sub_split_average
      end
    end
    normalize_time_data(average_time_hash, expected_time)
  end

  def normalize_time_data(time_data, expected_time)
    average_finish_time = time_data[{splits.last.id => 1}]
    return time_data unless average_finish_time
    factor = expected_time / average_finish_time
    time_data.each { |k, v| time_data[k] = v * factor }
  end

  def create_split_rows
    prior_time = 0
    result = []
    splits.each do |split|
      split_row = SplitRow.new(split, related_split_times(split), prior_time, start_time)
      result << split_row
      prior_time = split_row.times_from_start.last
    end
    result
  end

  def related_split_times(split)
    split.sub_split_key_hashes.collect { |key_hash| split_times[key_hash] }
  end

end