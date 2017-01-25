class LiveDataEntryReporter
  include TimeFormats

  def initialize(args)
    ArgsValidator.validate(params: args,
                           required: [:event, :params],
                           exclusive: [:event, :params, :effort_data],
                           class: self.class)
    @event = args[:event]
    @params = args[:params].symbolize_keys
    @effort_data = args[:effort_data] || NewLiveEffortData.new(event: event, params: params)
  end

  def full_report
    effort_data.response_row.merge({reportText: report_text,
                                    priorValidReportText: prior_valid_report_text,
                                    timeFromPriorValid: time_format_xxhyym(seconds_from_prior_valid),
                                    timeInAid: time_format_minutes(seconds_in_aid)})
  end

  private

  attr_reader :event, :params, :effort_data
  delegate :subject_lap_split, :effort, :new_split_times, :effort_lap_splits, :ordered_existing_split_times, to: :effort_data
  delegate :dropped_key, to: :effort

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
    "#{split_time_name(last_reported_split_time)} at #{day_time_military_format(last_reported_split_time.day_and_time)}" +
        dropped_addendum
  end

  def dropped_addendum
    case
    when dropped_key && dropped_key == last_reported_split_time.lap_split_key
      ' and dropped there'
    when dropped_key
      drop_conflict_report_text
    else
      ''
    end
  end

  def drop_conflict_report_text
    " but reported dropped at #{lap_split_name(dropped_lap_split)}" +
        (dropped_split_time ? " as of #{day_time_military_format(dropped_split_time.day_and_time)}" : '')
  end

  def prior_valid_report_text
    prior_valid_split_time ?
        "#{prior_valid_split_time.split_name} at #{day_time_military_format(prior_valid_split_time.day_and_time)}" : 'n/a'
  end

  def lap_split_name(lap_split)
    report_laps? ? lap_split.name : lap_split.name_without_lap
  end

  def split_time_name(split_time)
    report_laps? ? split_time.split_name_with_lap : split_time.split_name
  end

  def last_reported_split_time
    ordered_existing_split_times.last
  end

  def dropped_split_time
    dropped_key && ordered_existing_split_times.reverse.find { |st| st.lap_split_key == dropped_key }
  end

  def last_reported_lap_split
    find_lap_split(last_reported_split_time.lap_split_key)
  end

  def dropped_lap_split
    find_lap_split(dropped_key)
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
        PriorSplitTimeFinder.split_time(effort: effort,
                                        time_point: subject_lap_split.time_point_in,
                                        lap_splits: effort_lap_splits,
                                        split_times: ordered_existing_split_times)
  end

  def report_laps?
    event.laps_required != 1
  end

  def subject_split
    subject_lap_split.split
  end
end