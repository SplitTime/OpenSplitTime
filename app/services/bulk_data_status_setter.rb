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
    changed_split_times
    changed_efforts
  end

  def save_changes
    bulk_update(:split_times, changed_split_times)
    bulk_update(:efforts, changed_efforts)
    self.report = "Updated #{changed_split_times.size} split times and #{changed_efforts.size} efforts."
  end

  private

  attr_reader :efforts, :times_container, :grouped_split_times
  attr_writer :report

  def ordered_splits
    @ordered_splits ||= efforts.first.ordered_splits.to_a
  end

  def bulk_update(table, changed_resources)
    begin
      Upsert.batch(ActiveRecord::Base.connection, table) do |upsert|
        changed_resources.each do |resource|
          upsert.row({id: resource.id}, data_status: resource.data_status_numeric, updated_at: Time.now)
        end
      end
    rescue Exception => e
      puts "SQL error in #{ __method__ }"
      ActiveRecord::Base.connection.execute 'ROLLBACK'

      raise e
    end
  end
end