class LiveTimeSplitTimeCreator

  def self.create(args)
    new(args).create
  end

  def initialize(args)
    ArgsValidator.validate(params: args,
                           required: [:event, :live_times],
                           exclusive: [:event, :live_times],
                           class: self.class)
    @event = args[:event]
    @live_times = args[:live_times]
    validate_setup
  end

  def create
    created_split_time_ids = []
    creatable_split_times.each do |split_time|
      if split_time.save
        created_split_time_ids << split_time.id
        live_time = live_times.find { |lt| lt.id == split_time.live_time_id }
        live_time.update(split_time: split_time) if live_time
      end
    end
    created_split_times = SplitTime.where(id: created_split_time_ids).eager_load(:effort)
    updated_efforts = created_split_times.map(&:effort).uniq
    updated_efforts.each { |effort| EffortDataStatusSetter.set_data_status(effort: effort) }
    if event.available_live
      indexed_split_times = created_split_times.group_by { |st| st.effort.person_id || 0 }
      indexed_split_times.each do |person_id, split_times|
        NotifyFollowersJob.perform_later(person_id: person_id,
                                         split_time_ids: split_times.map(&:id),
                                         multi_lap: event.multiple_laps?) unless person_id.zero?
      end
    end
  end

  private

  attr_reader :event, :live_times

  def creatable_split_times
    creatable_effort_data_objects.map(&:proposed_split_times).flatten
  end

  def creatable_effort_data_objects
    effort_data_objects.select { |effort_data| effort_data.clean? && effort_data.valid? }
  end

  def effort_data_objects
    @effort_data_objects ||= LiveTimeRowConverter.new(event: event, live_times: live_times).effort_data_objects
  end

  def validate_setup
    raise ArgumentError, 'One or more LiveTimes does not relate to the provided Event' unless
        live_times.all? { |lt| lt.event_id == event.id }
  end
end
