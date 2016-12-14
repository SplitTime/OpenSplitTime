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
    effort_data.response_row.merge({:reportText => report_text,
                                    :priorValidReportText => prior_valid_report_text,
                                    :timeFromPriorValid => time_from_prior_valid,
                                    :timeInAid => time_in_aid})
  end

  private

  attr_reader :event, :params, :effort_data
  delegate :split, :effort, :dropped_here?, :new_split_times, :times_exist, :ordered_splits,
           :ordered_split_times, :ordered_existing_split_times, to: :effort_data
  delegate :dropped_split_id, to: :effort

  def report_text
    case
    when effort.null_record?
      'n/a'
    when last_reported_split_time.nil?
      'Not yet started'
    else
      "#{last_reported_split_time.split_name} at #{day_time_military_format(last_reported_split_time.day_and_time)}" +
          dropped_addendum
    end
  end

  def last_reported_split_time
    ordered_existing_split_times.last
  end

  def dropped_addendum
    case
    when dropped_split_id && dropped_split_id == last_reported_split_time.split_id
      ' and dropped there'
    when dropped_split_id
      " but reported dropped at #{dropped_split.base_name} as of #{day_time_military_format(dropped_split_time.day_and_time)}"
    else
      ''
    end
  end

  def dropped_split
    dropped_split_id && ordered_splits.find { |split| split.id == dropped_split_id }
  end

  def dropped_split_time
    dropped_split_id && ordered_existing_split_times.select { |st| st.split_id == dropped_split_id }.last
  end

  def prior_valid_report_text
    prior_valid_split_time ?
        "#{prior_valid_split_time.split_name} at #{day_time_military_format(prior_valid_split_time.day_and_time)}" : 'n/a'
  end

  def time_from_prior_valid
    seconds = first_new_split_time.try(:time_from_start) && prior_valid_split_time.try(:time_from_start) &&
        first_new_split_time.time_from_start - prior_valid_split_time.time_from_start
    time_format_xxhyym(seconds)
  end

  def first_new_split_time
    new_split_times.values.sort_by(&:bitkey).first
  end

  def prior_valid_split_time
    @prior_valid_split_time ||= PriorSplitTimeFinder.split_time(effort: effort,
                                                                sub_split: split.sub_split_in,
                                                                ordered_splits: ordered_splits,
                                                                split_times: ordered_existing_split_times)
  end

  def time_in_aid
    seconds = new_split_times[:in].try(:time_from_start) && new_split_times[:out].try(:time_from_start) &&
        new_split_times[:out].time_from_start - new_split_times[:in].time_from_start
    time_format_minutes(seconds)
  end
end