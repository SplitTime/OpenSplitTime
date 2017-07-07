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
    paired_live_times.map do |left_live_time, right_live_time|
      {split_id: left_live_time&.split_id || right_live_time&.split_id,
       bib_number: left_live_time&.bib_number || right_live_time&.bib_number,
       live_time_id_in: left_live_time&.id,
       live_time_id_out: right_live_time&.id,
       time_in: left_live_time&.military_time,
       time_out: right_live_time&.military_time,
       pacer_in: left_live_time&.with_pacer,
       pacer_out: right_live_time&.with_pacer,
       dropped_here: left_live_time&.stopped_here || right_live_time&.stopped_here,
       remarks: [left_live_time&.remarks, right_live_time&.remarks].join(' / ')}
    end
  end

  def paired_live_times
    EventLiveTimePairer.pair(event: event, live_times: live_times)
  end

  def ordered_splits
    @ordered_splits ||= event.ordered_splits.to_a
  end
end
