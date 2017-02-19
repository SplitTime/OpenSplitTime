class DroppedAttributesSetter

  def self.set_attributes(args)
    bulk_setter = new(args)
    bulk_setter.set_attributes
    bulk_setter.save_changes
    bulk_setter.report
  end

  def initialize(args)
    ArgsValidator.validate(params: args,
                           required: :efforts,
                           exclusive: :efforts,
                           class: self.class)
    @efforts = args[:efforts].with_ordered_split_times
    @changed_split_times = []
    @reports = []
  end

  def set_attributes
    efforts.each do |effort|
      unless effort.finished?
        effort.assign_attributes(dropped_split_id: effort.split_times.last.split_id,
                                 dropped_lap: effort.split_times.last.lap)
      end
      effort.split_times.each { |st| st.assign_attributes(stopped_here: false) }
      effort.split_times.last.assign_attributes(stopped_here: true)
      changed_split_times << effort.split_times.select(&:changed?)
    end
  end

  def changed_efforts
    efforts.select(&:changed?)
  end

  def save_changes
    reports << BulkUpdateService.update_attributes(:efforts, changed_effort_attributes)
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

  def changed_effort_attributes
    changed_efforts.map { |effort| [effort.id, {dropped_split_id: effort.dropped_split_id,
                                                dropped_lap: effort.dropped_lap}] }.to_h
  end
end