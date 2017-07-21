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
    creatable_split_times.each do |split_time|
      if split_time.save
        live_time = live_times.find { |lt| lt.id == split_time.live_time_id }
        live_time.update(split_time: split_time) if live_time
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
