class NewLiveEffortData
  attr_reader :ordered_splits, :effort, :new_split_times

  def initialize(args)
    ArgsValidator.validate(params: args,
                           required: [:event, :params],
                           exclusive: [:event, :params, :ordered_splits, :effort,
                                       :indexed_split_times, :times_container],
                           class: self.class)
    @event = args[:event]
    @params = args[:params].symbolize_keys
    @ordered_splits = args[:ordered_splits] || event.ordered_splits.to_a
    @effort = args[:effort] || event.efforts.find_guaranteed(bib_number: params[:bibNumber])
    @indexed_split_times = args[:indexed_split_times] || effort.split_times.index_by(&:sub_split)
    @existing_split_times = indexed_split_times.dup
    @times_container = args[:times_container] || SegmentTimesContainer.new(calc_model: :stats)
    @new_split_times = {}
    create_split_times
  end

  def split
    @split ||= ordered_splits.find { |split| split.id == params[:splitId].to_i } || Split.null_record
  end

  def dropped_here?
    params[:droppedHere] == 'true'
  end

  def times_exist
    new_split_times.map { |kind, split_time| [kind, existing_split_times[split_time.sub_split].present?] }.to_h
  end

  def time_in_aid
    new_split_times[:in].try(:time_from_start) && new_split_times[:out].try(:time_from_start) &&
        time_format_xxhyym(new_split_times[:out].time_from_start - new_split_times[:in].time_from_start)
  end

  def ordered_split_times
    ordered_splits.map(&:sub_splits).flatten.map { |sub_split| indexed_split_times[sub_split] }.compact
  end

  private

  attr_reader :event, :params, :indexed_split_times, :times_container, :existing_split_times

  def create_split_times
    sub_split_kinds.each do |kind|
      split_time = new_split_time(kind)
      split_time.data_status = times_container.data_status(segments[kind], split_time.time_from_start)
      self.new_split_times[kind] = split_time
      indexed_split_times[split_time.sub_split] = split_time if split_time.time_from_start
    end
  end

  def sub_split_kinds # Typically [:in] or [:in, :out]
    @sub_split_kinds ||= split.bitkeys.map { |bitkey| SubSplit.kind(bitkey).downcase.to_sym }
  end

  def sub_splits
    @sub_splits ||= split.sub_splits.map { |sub_split| [SubSplit.kind(sub_split.bitkey).downcase.to_sym, sub_split] }.to_h
  end

  def segments
    @segments ||= sub_split_kinds.map { |kind| [kind, Segment.new(begin_sub_split: ordered_splits.first.sub_split_in,
                                                                  end_sub_split: sub_splits[kind])] }.to_h
  end

  def new_split_time(kind)
    SplitTime.new(effort: effort,
                  sub_split: sub_splits[kind],
                  time_from_start: time_from_start(kind),
                  pacer: camelized_param('pacer', kind) == 'true')
  end

  def time_from_start(kind)
    day_and_time = day_and_time(kind)
    day_and_time && (day_and_time - event.start_time - effort.start_offset)
  end

  def day_and_time(kind)
    sub_splits[kind] && IntendedTimeCalculator.day_and_time(military_time: camelized_param('time', kind),
                                                            effort: effort,
                                                            sub_split: sub_splits[kind],
                                                            ordered_splits: ordered_splits,
                                                            split_times: ordered_split_times)
  end


  def camelized_param(base, kind)
    params["#{base}_#{kind}".camelize(:lower).to_sym]
  end
end