class DroppedAttributesSetter

  attr_reader :report

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
    @efforts = args[:efforts].sorted_with_finish_status
  end

  def set_attributes
    efforts.each do |effort|
      unless effort.finished?
        effort.assign_attributes(dropped_split_id: effort.final_split_id, dropped_lap: effort.final_lap)
      end
    end
  end

  def changed_efforts
    efforts.select(&:changed?)
  end

  def save_changes
    self.report = BulkUpdateService.update_attributes(:efforts, changed_effort_attributes)
  end

  private

  attr_reader :efforts, :times_container
  attr_writer :report

  def changed_effort_attributes
    changed_efforts.map { |effort| [effort.id, {dropped_split_id: effort.dropped_split_id,
                                                dropped_lap: effort.dropped_lap}] }.to_h
  end
end