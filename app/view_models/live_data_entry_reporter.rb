# frozen_string_literal: true

class LiveDataEntryReporter
  include TimeFormats

  def initialize(args)
    ArgsValidator.validate(params: args,
                           required: [:event, :params],
                           exclusive: [:event, :params, :effort_data],
                           class: self.class)
    @event = args[:event]
    @params = args[:params]
    @effort_data = args[:effort_data] || LiveEffortData.new(event: event, params: params)
  end

  def full_report
    effort_data.response_row.merge({report_text: report_text,
                                    prior_valid_report_text: prior_valid_report_text,
                                    time_from_prior_valid: time_format_xxhyym(seconds_from_prior_valid),
                                    time_in_aid: time_format_minutes(seconds_in_aid)})
        .camelize_keys
  end

  private

  attr_reader :event, :params, :effort_data
  delegate :subject_lap_split, :effort, :new_split_times, :effort_lap_splits, :ordered_existing_split_times, to: :effort_data

  def report_text
    case
    when effort.null_record?
      'n/a'
    when last_reported_split_time.nil?
      'Not yet started'
    else
      last_split_time_report_text
    end
  end

  def last_split_time_report_text
    reported_place_and_time(last_reported_split_time) + stopped_addendum
  end

  def stopped_addendum
    case
    when stopped_split_time && stopped_split_time.lap_split_key == last_reported_split_time.lap_split_key
      ' and stopped there'
    when stopped_split_time
      stop_conflict_report_text
    else
      ''
    end
  end

  def stop_conflict_report_text
    " but reported stopped at #{lap_split_name(stopped_lap_split)}" +
        (stopped_split_time ? " as of #{day_time_military_format(stopped_split_time.day_and_time)}" : '')
  end

  def prior_valid_report_text
    prior_valid_split_time ? reported_place_and_time(prior_valid_split_time) : 'n/a'
  end

  def reported_place_and_time(split_time)
    "#{split_time_name(split_time)} at #{day_time_military_format(split_time.day_and_time)}"
  end

  def lap_split_name(lap_split)
    return "[unknown split]" unless lap_split
    report_laps? ? lap_split.base_name : lap_split.base_name_without_lap
  end

  def split_time_name(split_time)
    report_laps? ? split_time.split_name_with_lap : split_time.split_name
  end

  def last_reported_split_time
    ordered_existing_split_times.last
  end

  def stopped_split_time
    ordered_existing_split_times.reverse.find(&:stopped_here)
  end

  def last_reported_lap_split
    find_lap_split(last_reported_split_time.lap_split_key)
  end

  def stopped_lap_split
    find_lap_split(stopped_split_time.lap_split_key)
  end

  def find_lap_split(lap_split_key)
    lap_split_key && effort_lap_splits.find { |lap_split| lap_split.key == lap_split_key }
  end

  def seconds_from_prior_valid
    first_new_split_time.try(:time_from_start) && prior_valid_split_time.try(:time_from_start) &&
        first_new_split_time.time_from_start - prior_valid_split_time.time_from_start
  end

  def seconds_in_aid
    new_split_times[:in].try(:time_from_start) && new_split_times[:out].try(:time_from_start) &&
        new_split_times[:out].time_from_start - new_split_times[:in].time_from_start
  end

  def first_new_split_time
    new_split_times.values.reject(&:null_record?).sort_by(&:bitkey).first
  end

  def prior_valid_split_time
    @prior_valid_split_time ||= subject_split.real_presence &&
        SplitTimeFinder.prior(effort: effort,
                              time_point: subject_lap_split.time_point_in,
                              lap_splits: effort_lap_splits,
                              split_times: ordered_existing_split_times)
  end

  def report_laps?
    event.multiple_laps?
  end

  def subject_split
    subject_lap_split.split
  end
end
