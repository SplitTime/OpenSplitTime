class NewLiveEffortData

  def initialize(args)
    ArgsValidator.validate(params: args,
                           required: [:event, :params],
                           exclusive: [:event, :params, :ordered_splits, :effort, :times_container],
                           class: self.class)
    @event = args[:event]
    @params = args[:params].symbolize_keys
    @ordered_splits = args[:ordered_splits] || event.ordered_splits.to_a
    @effort = args[:effort] || event.efforts.find_guaranteed(bib_number: params[:bibNumber])
    @times_container = args[:times_container] || SegmentTimesContainer.new(calc_model: :stats)
  end

  def response_row
    {:splitId => split.id,
     :splitName => split.base_name,
     :splitDistance => split.distance_from_start,
     :bibNumber => effort.bib_number,
     :effortName => effort.name,
     :droppedHere => dropped_here?,
     :timeIn => military_times[:in],
     :timeOut => military_times[:out],
     :pacerIn => pacers_present[:in],
     :pacerOut => pacers_present[:out],
     :timeInExists => times_exist[:in],
     :timeOutExists => times_exist[:out],
     :timeInStatus => time_statuses[:in],
     :timeOutStatus => time_statuses[:out]}
  end

  private

  attr_reader :event, :params, :ordered_splits, :effort, :times_container

  def sub_split_kinds # Typically [:in] or [:in, :out]
    @sub_split_kinds ||= split.bitkeys.map { |bitkey| SubSplit.kind(bitkey).downcase.to_sym }
  end

  def sub_splits
    split.sub_splits.map { |sub_split| [SubSplit.kind(sub_split.bitkey).downcase.to_sym, sub_split] }.to_h
  end

  def dropped_here?
    params[:droppedHere] == 'true'
  end

  def military_times
    sub_split_kinds.map { |kind| [kind, split_times[kind] && split_times[kind].military_time] }.to_h
  end

  def pacers_present
    @pacers_present ||= sub_split_kinds.map { |kind| [kind, camelized_param('pacer', kind) == 'true'] }.to_h
  end

  def times_exist
    @times_exist ||= sub_split_kinds.map { |kind| [kind, existing_split_times.map(&:sub_split).include?(SubSplit.bitkey(kind))] }.to_h
  end

  def time_statuses
    @time_statuses ||= sub_split_kinds.map { |kind| [kind, times_container.data_status(segments[kind], times_from_start[kind])] }.to_h
  end

  def segments
    @segments ||= sub_split_kinds.map { |kind| [kind, Segment.new(begin_sub_split: start_sub_split, end_sub_split: sub_splits[kind])] }.to_h
  end

  def split_times
    @split_times ||= sub_split_kinds.map { |kind| [kind, new_split_time(kind)] }.to_h
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

  def existing_split_times
    @existing_split_times ||= SplitTime.where(effort: effort, split: split)
  end

  def start_sub_split
    ordered_splits.first.sub_split_in
  end

  def new_split_time(kind)
    sub_splits[kind] && SplitTime.new(effort: effort, sub_split: sub_splits[kind], time_from_start: times_from_start[kind])
  end

  def time_from_start(kind)
    days_and_times[kind] && (days_and_times[kind] - event.start_time - effort.start_offset)
  end

  def intended_day_and_time(military_time, sub_split)
    sub_split && IntendedTimeCalculator.day_and_time(military_time: military_time, effort: effort, sub_split: sub_split)
  end

  def camelized_param(base, kind)
    params["#{base}_#{kind}".camelize(:lower).to_sym]
  end
end