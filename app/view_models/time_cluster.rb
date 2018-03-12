# frozen_string_literal: true

class TimeCluster
  attr_reader :split_times_data

  def initialize(args)
    ArgsValidator.validate(params: args,
                           required: [:finish, :split_times_data, :start_time],
                           exclusive: [:finish, :split_times_data, :prior_split_time,
                                       :immediate_prior_split_time, :start_time],
                           class: self.class)
    @finish = args[:finish]
    @split_times_data = args[:split_times_data]
    @prior_split_time = args[:prior_split_time]
    @immediate_prior_split_time = args[:immediate_prior_split_time]
    @start_time = args[:start_time]
  end

  def drop_display?
    immediate_prior_split_time.try(:stopped_here)
  end

  def finish?
    @finish
  end

  def aid_time_recordable?
    times_from_start.count > 1
  end

  def segment_time
    @segment_time ||=
        times_from_start.compact.first - prior_time if (prior_time && (times_from_start.compact.present?))
  end

  def time_in_aid
    @time_in_aid ||=
        times_from_start.compact.last - times_from_start.compact.first if times_from_start.compact.size > 1
  end

  def times_from_start
    @times_from_start ||= split_times_data.map { |st| st && st[:time_from_start] }
  end

  def days_and_times
    @days_and_times ||= times_from_start.map { |time| time && (start_time + time.seconds) }
  end

  def time_data_statuses
    @time_data_statuses ||= split_times_data.map { |st| st && st[:data_status] }
  end

  def split_time_ids
    @split_time_ids ||= split_times_data.map { |st| st && st[:id] }
  end

  def stopped_here_flags
    @stopped_here_flags ||= split_times_data.map { |st| st && st[:stopped_here] }
  end

  private

  attr_reader :split, :start_time, :prior_split_time, :immediate_prior_split_time

  def prior_time
    prior_split_time.try(:time_from_start)
  end
end
