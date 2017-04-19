class BulkDataStatusSetter
  include BackgroundNotifiable

  attr_reader :changed_split_times, :changed_efforts, :report

  def self.set_data_status(args)
    bulk_setter = new(args)
    bulk_setter.set_data_status
    bulk_setter.save_changes
    bulk_setter.report
  end

  def initialize(args)
    ArgsValidator.validate(params: args,
                           required: :efforts,
                           exclusive: [:efforts, :calc_model, :times_container, :background_channel],
                           class: self.class)
    @efforts = args[:efforts]
    @times_container = args[:times_container] || SegmentTimesContainer.new(calc_model: args[:calc_model] || :stats)
    @background_channel = args[:background_channel]
    @changed_split_times = []
    @changed_efforts = []
  end

  def set_data_status
    total_efforts = efforts.size
    efforts.each_with_index do |effort, i|
      setter = effort_setter(effort)
      setter.set_data_status
      changed_split_times.push(*setter.changed_split_times)
      changed_efforts.push(*setter.changed_efforts)
      current_effort = i
      report_progress(action: 'set status for', resource: 'effort', current: current_effort, total: total_efforts)
    end
  end

  def save_changes
    report_status(message: 'Saving status changes for split times...')
    split_time_report = BulkUpdateService.update_attributes(:split_times, changed_split_time_attributes)
    report_status(message: 'Saving status changes for efforts...')
    effort_report = BulkUpdateService.update_attributes(:efforts, changed_effort_attributes)
    report_status(message: 'Saving status changes for efforts...done')
    self.report = "#{split_time_report} #{effort_report}"
  end

  private

  attr_reader :efforts, :times_container, :background_channel
  attr_writer :report

  def effort_setter(effort)
    EffortDataStatusSetter.new(effort: effort,
                               ordered_split_times: grouped_split_times[effort.id],
                               lap_splits: lap_splits,
                               times_container: times_container)
  end

  def grouped_split_times
    @grouped_split_times ||= all_split_times.group_by(&:effort_id)
  end

  def all_split_times
    SplitTime.where(effort: efforts).ordered
  end

  def changed_split_time_attributes
    changed_split_times.map { |st| [st.id, {data_status: st.data_status_numeric}] }.to_h
  end

  def changed_effort_attributes
    changed_efforts.map { |effort| [effort.id, {data_status: effort.data_status_numeric}] }.to_h
  end

  def lap_splits
    @lap_splits ||= event.required_lap_splits.presence || event.lap_splits_through(highest_lap)
  end

  def event
    @event ||= efforts.first.event
  end

  def highest_lap
    all_split_times.map(&:lap).max || 1
  end
end