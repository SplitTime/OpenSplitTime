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
    @efforts = args[:efforts].started.with_ordered_split_times
    @changed_split_times = []
    @reports = []
  end

  def set_attributes
    efforts.each do |effort|
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