# frozen_string_literal: true

class EffortProgressData

  attr_reader :effort, :split_times
  delegate :topic_resource_key, to: :effort

  def initialize(args)
    ArgsValidator.validate(params: args,
                           required: [:effort, :split_times],
                           exclusive: [:effort, :split_times],
                           class: self.class)
    @effort = args[:effort]
    @split_times = args[:split_times]
  end

  def effort_data
    @effort_data ||= {full_name: full_name,
                      event_name: event_name,
                      split_times_data: split_times_data,
                      effort_id: effort.id}
  end

  private

  delegate :full_name, :event_name, to: :effort

  def split_times_data
    split_times.sort_by(&:absolute_time).map do |split_time|
      {split_name: split_name(split_time),
       split_distance: split_distance(split_time),
       absolute_time_local: split_time.absolute_time_local.strftime('%A %l:%M%p'),
       elapsed_time: TimeConversion.seconds_to_hms(split_time.time_from_start.to_i),
       pacer: split_time.pacer,
       stopped_here: split_time.stopped_here}
    end
  end

  def multi_lap?
    split_times.any? { |split_time| split_time.lap > 1 }
  end

  def split_distance(split_time)
    split_time.total_distance
  end

  def split_name(split_time)
    multi_lap? ? split_time.split_name_with_lap : split_time.split_name
  end
end
