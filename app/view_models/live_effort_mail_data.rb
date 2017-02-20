class LiveEffortMailData

  attr_reader :participant, :split_times, :followers

  def initialize(args)
    ArgsValidator.validate(params: args,
                           required_alternatives: [:participant, :participant_id],
                           exclusive: [:participant, :participant_id, :split_times, :split_time_ids],
                           class: self.class)
    @participant = args[:participant] || Participant.find(args[:participant_id])
    @split_times = args[:split_times] || SplitTime.find(args[:split_time_ids])
    @effort = split_times.first.effort
    @followers = participant.followers
  end

  def effort_data
    @effort_data ||= {full_name: full_name,
                      event_name: event_name,
                      split_times_data: split_times_data,
                      effort_id: effort.id,
                      event_id: effort.event.id}
  end

  private

  attr_reader :effort

  delegate :full_name, :event_name, to: :effort

  def split_times_data
    split_times.map do |split_time|
      {time_point: split_time.time_point,
       split_name: split_time.split_name,
       day_and_time: split_time.day_and_time.strftime("%A, %B %-d, %Y %l:%M%p"),
       pacer: split_time.pacer,
       stopped_here: split_time.stopped_here}
    end
  end
end