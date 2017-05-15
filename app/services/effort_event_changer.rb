class EffortEventChanger

  def self.update(args)
    new(args).assign_event
  end

  def initialize(args)
    ArgsValidator.validate(params: args, required: [:effort, :event], exclusive: [:effort, :event], class: self.class)
    @effort = args[:effort]
    @event = args[:event]
    @old_event ||= effort.event
    @split_times ||= effort.ordered_split_times.select('split_times.*, splits.distance_from_start')
    verify_compatibility
  end

  def assign_event
    existing_start_time = effort.start_time
    effort.event = event
    effort.start_time = existing_start_time
    split_times.each { |st| st.split = splits_by_distance[st.distance_from_start] }
    save_changes
  end

  private

  attr_reader :effort, :event, :split_times

  def save_changes
    ActiveRecord::Base.transaction do
      effort.save! if effort.changed?
      split_times.each { |st| st.save! if st.changed? }
    end
  end

  def maximum_lap
    @maximum_lap ||= event.laps_required == 0 ? Float::INFINITY : event.laps_required
  end

  def distances
    @distances ||= splits_by_distance.keys
  end

  def splits_by_distance
    @splits_by_distance ||= event.splits.index_by(&:distance_from_start)
  end

  def verify_compatibility
    raise ArgumentError, "#{effort} cannot be assigned to #{event} because distances do not coincide" unless
        split_times.all? { |st| distances.include?(st.distance_from_start) }
    raise ArgumentError, "#{effort} cannot be assigned to #{event} because sub splits do not coincide" unless
        split_times.all? { |st| splits_by_distance[st.distance_from_start].sub_split_bitkeys.include?(st.bitkey) }
    raise ArgumentError, "#{effort} cannot be assigned to #{event} because laps exceed maximum required" unless
        split_times.all? { |st| maximum_lap >= st.lap }
  end
end
