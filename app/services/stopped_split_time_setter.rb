class StoppedSplitTimeSetter

  def self.stop(args)
    setter = new(args)
    setter.stop
    setter.save_changes
    setter.report
  end

  def initialize(args)
    ArgsValidator.validate(params: args,
                           required: :efforts,
                           exclusive: :efforts,
                           class: self.class)
    @efforts = args[:efforts].with_ordered_split_times.select(&:started?)
    @changed_split_times = []
    @reports = []
  end

  def stop
    efforts.each do |effort|
      next unless effort.split_times.present?
      effort.split_times.each { |st| st.assign_attributes(stopped_here: false) }
      effort.split_times.last.assign_attributes(stopped_here: true)
      changed_split_times << effort.split_times.select(&:changed?)
    end
  end

  def save_changes
    reports << BulkUpdateService.update_attributes(:split_times, changed_split_time_attributes)
  end

  def report
    reports.join(' / ')
  end

  private

  attr_reader :efforts, :changed_split_times, :reports

  def changed_split_time_attributes
    changed_split_times.flatten.map { |st| [st.id, {stopped_here: st.stopped_here}] }
  end
end