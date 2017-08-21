class LiveEffortMailData

  attr_reader :participant, :split_times
  delegate :topic_resource_key, to: :participant

  def initialize(args)
    ArgsValidator.validate(params: args,
                           required_alternatives: [:participant, :participant_id],
                           exclusive: [:participant, :participant_id, :split_times, :split_time_ids, :multi_lap],
                           class: self.class)
    @participant = args[:participant] || Participant.friendly.find(args[:participant_id])
    @split_times = args[:split_times] || SplitTime.where(id: args[:split_time_ids])
                                             .eager_load(:split, effort: :event)
    @multi_lap = args[:multi_lap] || false
  end

  def effort_data
    @effort_data ||= {full_name: full_name,
                      event_name: event_name,
                      split_times_data: split_times_data,
                      effort_slug: effort.slug,
                      event_slug: effort.event.slug}
  end

  def followers
    @followers ||= participant.followers
  end

  private

  delegate :full_name, :event_name, to: :effort

  def effort
    @effort ||= split_times.first.effort
  end

  def split_times_data
    split_times.map do |split_time|
      {split_name: split_name(split_time),
       split_distance: split_distance(split_time),
       day_and_time: split_time.day_and_time.strftime('%A, %B %-d, %Y %l:%M%p'),
       pacer: split_time.pacer,
       stopped_here: split_time.stopped_here}
    end
  end

  def multi_lap?
    @multi_lap
  end

  def split_distance(split_time)
    split_time.lap_split.distance_from_start
  end

  def split_name(split_time)
    multi_lap? ? split_time.split_name_with_lap : split_time.split_name
  end
end
