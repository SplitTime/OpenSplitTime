class LiveEffortMailData

  attr_reader :participant, :split_times, :followers

  def initialize(participant_id, split_time_ids)
    @participant = Participant.find(participant_id)
    @split_times = SplitTime.find(split_time_ids)
    @effort = @split_times.first.effort
    @followers = @participant.followers
  end

  def effort_data
    @effort_data ||= get_effort_data
  end

  private

  attr_reader :effort

  delegate :full_name, :event_name, :dropped_split_id, to: :effort

  def get_effort_data
    {full_name: full_name,
     event_name: event_name,
     dropped_split_id: dropped_split_id,
     split_times_data: split_times_data}
  end

  def split_times_data
    result = []
    split_times.each do |split_time|
      result << {split_id: split_time.split_id,
                 split_name: split_time.split_name,
                 day_and_time: split_time.day_and_time.strftime("%B %-d, %Y %l:%M%p"),
                 pacer: split_time.pacer}
    end
    result
  end

end