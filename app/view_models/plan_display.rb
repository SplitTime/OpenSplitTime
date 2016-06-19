class PlanDisplay
  attr_reader :course, :expected_time, :start_time, :relevant_events, :relevant_efforts, :split_rows

  MAX_EVENTS = 5

  def initialize(course, params)
    @course = course
    @event = course.events.latest
    @expected_time = expected_time_from_param(params[:expected_time])
    if @event
      @start_time = params[:start_time].present? ? convert_to_datetime(params[:start_time]) : default_start_time
    end
    if @event && @expected_time
      @relevant_events = course.events.recent(MAX_EVENTS)
      @relevant_efforts = course.relevant_efforts(expected_time, MAX_EVENTS).to_a
      @splits = event.ordered_splits.to_a
      @split_times = create_plan_split_times
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

  attr_reader :event, :splits, :split_times

  def expected_time_from_param(entered_time)
    return nil unless entered_time.present?
    clean_time = entered_time.gsub(/[^\d:]/, '')
    clean_time.concat("00") if entered_time.last == ":"
    return nil unless clean_time =~ /^\d{1,2}(:\d{2})?$/
    time_components = clean_time.split(":")
    hours = time_components[0].to_i
    minutes = time_components[1].to_i
    ((hours * 60 * 60) + (minutes * 60))
  end

  def create_plan_split_times # Temporary split_time objects to assist in constructing the view
    plan_times = calculate_plan_times
    result = []
    splits.each do |split|
      split.sub_split_bitkeys.each do |key|
        split_time = SplitTime.new(split: split, sub_split_bitkey: key, time_from_start: plan_times[{split.id => key}])
        result << split_time
      end
    end
    result.index_by(&:bitkey_hash)
  end

  def calculate_plan_times # Hash of {{split.id => bitkey} => plan_time_from_start}
    average_time_hash = {}
    splits.each do |split|
      split.sub_split_bitkeys.each do |bitkey|
        sub_split_average = split.average_time(bitkey, relevant_efforts)
        average_time_hash[{split.id => bitkey}] = sub_split_average
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
    split.sub_split_bitkey_hashes.collect { |key_hash| split_times[key_hash] }
  end

  def default_start_time
    years_prior = Time.now.year - event.start_time.year
    shift_forward = (years_prior * 52.weeks) + ((years_prior / 6).weeks)
    event.start_time + shift_forward
  end

  def convert_to_datetime(datetime_components)
    DateTime.new(datetime_components["date(1i)"].to_i,
                 datetime_components["date(2i)"].to_i,
                 datetime_components["date(3i)"].to_i,
                 datetime_components["date(4i)"].to_i,
                 datetime_components["date(5i)"].to_i)
  end

end