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

  def response_row
    {:splitId => split.id,
     :splitName => split.base_name,
     :splitDistance => split.distance_from_start,
     :effortId => effort.id,
     :bibNumber => effort.bib_number,
     :name => effort_name,
     :droppedHere => dropped_here?,
     :timeIn => new_split_times[:in].military_time,
     :timeOut => new_split_times[:out].military_time,
     :pacerIn => new_split_times[:in].pacer,
     :pacerOut => new_split_times[:out].pacer,
     :timeInStatus => new_split_times[:in].data_status,
     :timeOutStatus => new_split_times[:out].data_status,
     :timeInExists => times_exist[:in],
     :timeOutExists => times_exist[:out],
     :reportText => report_text,
     :priorValidReportText => prior_valid_report_text,
     :timeFromPriorValid => time_from_prior_valid,
     :timeInAid => time_in_aid}
  end

  private

  attr_reader :event, :params, :effort_data
  delegate :split, :effort, :dropped_here?, :new_split_times, :times_exist,
           :ordered_splits, :ordered_split_times, to: :effort_data

  def effort_name
    effort.try(:full_name) || (params[:bibNumber].present? ? 'Bib number not located' : 'n/a')
  end

  def report_text
    case
    when effort.nil?
      'n/a'
    when last_reported_split_time.nil?
      'Not yet started'
    else
      "#{last_reported_split_time.split_name} at #{day_time_military_format(last_reported_split_time.day_and_time)}"
    end
  end

  def last_reported_split_time
    ordered_split_times.last
  end

  def prior_valid_report_text
    prior_valid_split_time ?
        "#{prior_valid_split_time.split_name} at #{day_time_military_format(prior_valid_split_time.day_and_time)}" : 'n/a'
  end

  def time_from_prior_valid
    first_new_split_time.try(:time_from_start) && prior_valid_split_time.try(:time_from_start) &&
        time_format_xxhyym(first_new_split_time.time_from_start - prior_valid_split_time.time_from_start)
  end

  def first_new_split_time
    new_split_times.values.sort_by(&:bitkey).first
  end

  def prior_valid_split_time
    @prior_valid_split_time ||= PriorSplitTimeFinder.split_time(effort: effort,
                                                                sub_split: split.sub_split_in,
                                                                ordered_splits: ordered_splits,
                                                                split_times: ordered_split_times)
  end

  def time_in_aid
    new_split_times[:in].try(:time_from_start) && new_split_times[:out].try(:time_from_start) &&
        time_format_xxhyym(new_split_times[:out].time_from_start - new_split_times[:in].time_from_start)
  end
end