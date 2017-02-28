class BulkEffortsStopper

  def self.stop(args)
    stopper = new(args)
    stopper.assign_stops_to_final
    stopper.save_changes
    stopper.report
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

  def assign_stops_to_final
    efforts.each do |effort|
      next unless effort.split_times.present?
      effort_stopper = EffortStopper.new(effort: effort,
                                         ordered_split_times: effort.split_times,
                                         stopped_split_time: effort.split_times.last)
      effort_stopper.assign_stop
      changed_split_times << effort_stopper.changed_split_times
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