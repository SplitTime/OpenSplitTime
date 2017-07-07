class LiveTimeRowConverter

  def self.convert(args)
    new(args).convert
  end

  def initialize(args)
    ArgsValidator.validate(params: args,
                           required: [:event, :live_times],
                           exclusive: [:event, :live_times, :times_container],
                           class: self.class)
    @event = args[:event]
    @live_times = args[:live_times]
    @times_container = args[:times_container] || SegmentTimesContainer.new(calc_model: :stats)
  end

  def convert
    transformed_rows.reject { |row| row[:identical] }
  end

  def transformed_rows
    @transformed_rows ||= time_rows.map do |time_row|
      LiveEffortData.response_row(event: event,
                                  params: time_row,
                                  times_container: times_container,
                                  ordered_splits: ordered_splits)
    end
  end

  private

  attr_reader :event, :live_times, :times_container

  def time_rows
    paired_live_times.map { |left_lt, right_lt| {split_id: left_lt.split_id || right_lt.split_id,
                                                 bib_number: left_lt.bib_number || right_lt.bib_number,
                                                 time_in: left_lt.absolute_time,
                                                 time_out: right_lt.absolute_time,
                                                 pacer_in: left_lt.with_pacer,
                                                 pacer_out: right_lt.with_pacer,
                                                 stopped_here: left_lt.stopped_here || right_lt.stopped_here,
                                                 remarks: [left_lt.remarks, right_lt.remarks].join(' / ')} }
  end

  def paired_live_times
    EventLiveTimePairer.pair(event: event, live_times: live_times)
  end

  def ordered_splits
    @ordered_splits ||= event.ordered_splits.to_a
  end
end
