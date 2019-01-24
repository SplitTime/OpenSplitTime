# frozen_string_literal: true

class TimeCluster
  attr_reader :split_times_data

  def initialize(args)
    ArgsValidator.validate(params: args,
                           required: [:split_times_data, :finish],
                           exclusive: [:split_times_data, :finish, :show_indicator_for_stop],
                           class: self.class)
    @split_times_data = args[:split_times_data]
    @finish = args[:finish]
    @show_indicator_for_stop = args[:show_indicator_for_stop] || false
  end

  def finish?
    @finish
  end

  def show_stop_indicator?
    stopped_here? && show_indicator_for_stop?
  end

  def aid_time_recordable?
    split_times_data.many?
  end

  def segment_time
    @segment_time ||= compacted_segment_times.first
  end

  def time_in_aid
    @time_in_aid ||= compacted_segment_times.last if compacted_segment_times.many?
  end

  def times_from_start
    @times_from_start ||= split_times_data.map(&:time_from_start)
  end

  def absolute_times_local
    @absolute_times_local ||= split_times_data.map(&:absolute_time_local)
  end

  def absolute_times_local_strings
    @absolute_times_local_strings ||= split_times_data.map(&:absolute_time_local_string)
  end

  def absolute_estimates_early_local
    split_times_data.map(&:absolute_estimate_early_local)
  end

  def absolute_estimates_late_local
    split_times_data.map(&:absolute_estimate_late_local)
  end

  def time_data_statuses
    @time_data_statuses ||= split_times_data.map(&:data_status)
  end

  def pacer_flags
    @pacer_flags ||= split_times_data.map(&:pacer)
  end

  def stopped_here_flags
    @stopped_here_flags ||= split_times_data.map(&:stopped_here?)
  end

  def split_time_ids
    @split_time_ids ||= split_times_data.map(&:id)
  end

  def stopped_here?
    @stopped_here ||= stopped_here_flags.any?
  end

  private

  def show_indicator_for_stop?
    @show_indicator_for_stop
  end

  def compacted_segment_times
    @compacted_segment_times ||= split_times_data.map(&:segment_time).compact
  end
end
