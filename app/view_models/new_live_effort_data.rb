class NewLiveEffortData
  include TimeFormats

  def initialize(args)
    ArgsValidator.validate(params: args,
                           required: [:event, :params],
                           exclusive: [:event, :params, :ordered_splits, :effort, :times_container],
                           class: self.class)
    @event = args[:event]
    @params = args[:params].symbolize_keys
    @ordered_splits = args[:ordered_splits] || event.ordered_splits.to_a
    @effort = args[:effort] || event.efforts.find_guaranteed(bib_number: params[:bibNumber])
    @indexed_split_times = args[:indexed_split_times] || effort.split_times.index_by(&:sub_split)
    @existing_split_times = indexed_split_times.dup
    @times_container = args[:times_container] || SegmentTimesContainer.new(calc_model: :stats)
    insert_split_times
  end

  def response_row
    {:splitId => split.id,
     :splitName => split.base_name,
     :splitDistance => split.distance_from_start,
     :bibNumber => effort.bib_number,
     :effortName => effort_name,
     :droppedHere => dropped_here?,
     :timeIn => military_times[:in],
     :timeOut => military_times[:out],
     :pacerIn => pacers_present[:in],
     :pacerOut => pacers_present[:out],
     :timeInExists => times_exist[:in],
     :timeOutExists => times_exist[:out],
     :timeInStatus => time_statuses[:in],
     :timeOutStatus => time_statuses[:out],
     :reportText => report_text,
     :priorValidReportText => prior_valid_report_text,
     :timeFromPriorValid => time_from_prior_valid,
     :timeInAid => time_in_aid}
  end

  private

  attr_reader :event, :params, :ordered_splits, :effort, :indexed_split_times, :times_container, :existing_split_times


  def insert_split_times
    new_split_times.each_value { |split_time| indexed_split_times[split_time.sub_split] = split_time }
  end

  def ordered_split_times
    ordered_splits.map(&:sub_splits).flatten.map { |sub_split| indexed_split_times[sub_split] }.compact
  end

  def sub_split_kinds # Typically [:in] or [:in, :out]
    @sub_split_kinds ||= split.bitkeys.map { |bitkey| SubSplit.kind(bitkey).downcase.to_sym }
  end

  def sub_splits
    split.sub_splits.map { |sub_split| [SubSplit.kind(sub_split.bitkey).downcase.to_sym, sub_split] }.to_h
  end

  def effort_name
    effort.try(:full_name) || (params[:bibNumber].present? ? 'Bib number not located' : 'n/a')
  end

  def dropped_here?
    params[:droppedHere] == 'true'
  end

  def military_times
    sub_split_kinds.map { |kind| [kind, new_split_times[kind] && new_split_times[kind].military_time] }.to_h
  end

  def pacers_present
    @pacers_present ||= sub_split_kinds.map { |kind| [kind, camelized_param('pacer', kind) == 'true'] }.to_h
  end

  def time_statuses
    @time_statuses ||= sub_split_kinds.map { |kind| [kind, times_container.data_status(segments[kind], times_from_start[kind])] }.to_h
  end

  def times_exist
    new_split_times.map { |kind, split_time| [kind, existing_split_times[split_time.sub_split].present?] }.to_h
  end

  def report_text
    case
    when effort.nil?
      'n/a'
    when last_reported_split_time.nil?
      'Not yet started'
    else
      "#{last_reported_split_time.split_name} at #{day_time_military_format(last_reported_split_time.day_and_time)}"
    end
  end

  def prior_valid_report_text
    prior_valid_split_time ?
        "#{prior_valid_split_time.split_name} at #{day_time_military_format(prior_valid_split_time.day_and_time)}" : 'n/a'
  end

  def time_from_prior_valid
    first_new_split_time && prior_valid_split_time &&
        time_format_xxhyym(first_new_split_time.time_from_start - prior_valid_split_time.time_from_start)
  end

  def first_new_split_time
    sub_split_kinds.map { |kind| new_split_times[kind] }.compact.first
  end

  def time_in_aid
    new_split_times[:in] && new_split_times[:out] &&
        time_format_xxhyym(new_split_times[:out].time_from_start - new_split_times[:in].time_from_start)
  end

  def segments
    @segments ||= sub_split_kinds.map { |kind| [kind, Segment.new(begin_sub_split: start_sub_split, end_sub_split: sub_splits[kind])] }.to_h
  end

  def new_split_times
    @new_split_times ||= sub_split_kinds.map { |kind| [kind, new_split_time(kind)] }.to_h
  end

  def times_from_start
    @times_from_start ||= sub_split_kinds.map { |kind| [kind, time_from_start(kind)] }.to_h
  end

  def days_and_times
    @days_and_times ||= sub_split_kinds.map { |kind| [kind, intended_day_and_time(camelized_param('time', kind), sub_splits[kind])] }.to_h
  end

  def split
    @split ||= Split.find_guaranteed(id: params[:splitId])
  end

  def start_sub_split
    ordered_splits.first.sub_split_in
  end

  def finish_sub_split
    ordered_splits.last.sub_split_in
  end

  def new_split_time(kind)
    sub_splits[kind] && SplitTime.new(effort: effort, sub_split: sub_splits[kind], time_from_start: times_from_start[kind])
  end

  def time_from_start(kind)
    days_and_times[kind] && (days_and_times[kind] - event.start_time - effort.start_offset)
  end

  def intended_day_and_time(military_time, sub_split)
    sub_split && IntendedTimeCalculator.day_and_time(military_time: military_time,
                                                     effort: effort,
                                                     sub_split: sub_split,
                                                     ordered_splits: ordered_splits,
                                                     split_times: ordered_split_times)
  end

  def last_reported_split_time
    ordered_split_times.last
  end

  def prior_valid_split_time
    @prior_valid_split_time = effort && split && PriorSplitTimeFinder.new(effort: effort,
                                                                          sub_split: split.sub_split_in,
                                                                          ordered_splits: ordered_splits,
                                                                          split_times: ordered_split_times).split_time
  end

  def camelized_param(base, kind)
    params["#{base}_#{kind}".camelize(:lower).to_sym]
  end
end