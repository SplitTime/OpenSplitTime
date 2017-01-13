class BulkDataStatusSetter

  attr_reader :changed_split_times, :changed_efforts, :report

  def self.set_data_status(args)
    setter = new(args)
    setter.set_data_status
    setter.save_changes
    setter.report
  end

  def initialize(args)
    ArgsValidator.validate(params: args,
                           required: :efforts,
                           exclusive: [:efforts, :times_container],
                           class: self.class)
    @efforts = args[:efforts]
    @times_container = args[:times_container] || SegmentTimesContainer.new(calc_model: :stats)
    @grouped_split_times = SplitTime.basic_components.where(effort: efforts).ordered.group_by(&:effort_id)
    @changed_split_times = []
    @changed_efforts = []
  end

  def set_data_status
    efforts.each do |effort|
      setter = EffortDataStatusSetter.new(effort: effort,
                                          ordered_split_times: grouped_split_times[effort.id],
                                          ordered_splits: ordered_splits,
                                          times_container: times_container)
      setter.set_data_status
      changed_split_times.push(*setter.changed_split_times)
      changed_efforts.push(*setter.changed_efforts)
    end
  end

  def save_changes
    split_time_report = BulkUpdateService.update_attributes(:split_times, changed_split_time_attributes)
    effort_report = BulkUpdateService.update_attributes(:efforts, changed_effort_attributes)
    self.report = "#{split_time_report} #{effort_report}"
  end

  private

  attr_reader :efforts, :times_container, :grouped_split_times
  attr_writer :report

  def changed_split_time_attributes
    changed_split_times.map { |st| [st.id, {data_status: st.data_status_numeric}] }.to_h
  end

  def changed_effort_attributes
    changed_efforts.map { |effort| [effort.id, {data_status: effort.data_status_numeric}] }.to_h
  end

  def ordered_splits
    @ordered_splits ||= efforts.first.ordered_splits.to_a
  end
end