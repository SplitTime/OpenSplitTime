class NewLiveEffortData
  attr_reader :ordered_splits, :effort, :new_split_times, :indexed_existing_split_times
  delegate :participant_id, to: :effort
  SUB_SPLIT_KINDS ||= SubSplit.kinds.map { |kind| kind.downcase.to_sym }
  ASSUMED_LAP ||= 1

  def initialize(args)
    ArgsValidator.validate(params: args,
                           required: [:event, :params],
                           exclusive: [:event, :params, :ordered_splits, :effort, :times_container],
                           class: self.class)
    @event = args[:event]
    @params = args[:params].symbolize_keys
    @ordered_splits = args[:ordered_splits] || event.ordered_splits.to_a
    @effort = args[:effort] || event.efforts.find_guaranteed(bib_number: params[:bibNumber])
    @times_container = args[:times_container] || SegmentTimesContainer.new(calc_model: :stats)
    @indexed_existing_split_times = ordered_existing_split_times.index_by(&:time_point)
    @new_split_times = {}
    create_split_times
    fill_with_null_split_times
    validate_setup
  end

  def response_row
    {splitId: subject_split.id,
     lap: lap,
     lapFulfillsRequired: lap == event.laps_required,
     lapBeyondRequired: lap > event.laps_required,
     expectedLap: expected_lap,
     splitName: subject_split.base_name,
     splitDistance: subject_lap_split.distance_from_start,
     effortId: effort.id,
     bibNumber: effort.bib_number,
     effortName: effort_name,
     droppedHere: dropped_here?,
     timeIn: new_split_times[:in].military_time,
     timeOut: new_split_times[:out].military_time,
     pacerIn: new_split_times[:in].pacer,
     pacerOut: new_split_times[:out].pacer,
     timeInStatus: new_split_times[:in].data_status,
     timeOutStatus: new_split_times[:out].data_status,
     timeInExists: times_exist[:in],
     timeOutExists: times_exist[:out]}
  end

  def valid?
    subject_split.real_record? && effort.real_record? && lap.present?
  end

  def clean?
    times_exist.values.none? && proposed_split_times.all?(&:valid_status?)
  end

  def subject_lap_split
    @subject_lap_split ||= LapSplit.new(lap, subject_split)
  end

  def subject_split
    @subject_split ||= ordered_splits.find { |split| split.id == params[:splitId].to_i } || Split.null_record
  end

  def lap
    @lap ||= params[:lap].presence.try(:to_i) || ASSUMED_LAP
  end

  def expected_lap
    case
    when event.laps_required == 1
      1
    when subject_split.null_record? || effort.null_record?
      nil
    else
      ExpectedLapFinder.lap(ordered_split_times: ordered_existing_split_times, split: subject_split)
    end
  end

  def split_id
    subject_split.id
  end

  def effort_name
    effort.try(:full_name) || (params[:bibNumber].present? ? 'Bib number not located' : 'n/a')
  end

  def dropped_here?
    params[:droppedHere] == 'true'
  end

  def times_exist
    sub_split_kinds.map { |kind| [kind, indexed_existing_split_times[time_points[kind]].present?] }.to_h
  end

  def ordered_split_times
    effort_time_points.map { |time_point| indexed_split_times[time_point] }.compact
  end

  def proposed_split_times
    new_split_times.values.select(&:time_from_start)
  end

  def ordered_existing_split_times
    @ordered_existing_split_times ||= effort.ordered_split_times.to_a.freeze
  end

  def effort_lap_splits
    @effort_lap_splits ||= event.required_lap_splits.presence || (lap && event.lap_splits_through(lap)) || []
  end

  private

  attr_reader :event, :params, :times_container

  def indexed_split_times
    @indexed_split_times ||= confirmed_good_split_times.index_by(&:time_point)
  end

  def effort_time_points
    @effort_time_points ||= effort_lap_splits.map(&:time_points).flatten
  end

  # Temporarily change good split_times to confirmed; this optimizes #create_split_times
  # by preventing EffortDataStatusSetter from rechecking the status of good times
  def confirmed_good_split_times
    ordered_existing_split_times.dup.each { |st| st.data_status = 'confirmed' if st.good? }
  end

  def create_split_times
    sub_split_kinds.each do |kind|
      split_time = new_split_time(kind)
      if split_time.time_from_start
        indexed_split_times[split_time.time_point] = split_time
        EffortDataStatusSetter.new(effort: effort,
                                   ordered_split_times: ordered_split_times,
                                   lap_splits: effort_lap_splits,
                                   times_container: times_container).set_data_status
      end
      self.new_split_times[kind] = split_time
    end
  end

  def fill_with_null_split_times
    SUB_SPLIT_KINDS.each { |kind| self.new_split_times[kind] ||= SplitTime.null_record }
  end

  def sub_split_kinds # Typically [:in] or [:in, :out]
    @sub_split_kinds ||= subject_split.bitkeys.map { |bitkey| SubSplit.kind(bitkey).downcase.to_sym }
  end

  def time_points
    @time_points ||=
        subject_lap_split.time_points.map { |time_point| [time_point.kind.downcase.to_sym, time_point] }.to_h
  end

  def new_split_time(kind)
    SplitTime.new(effort: effort,
                  time_point: time_points[kind],
                  time_from_start: time_from_start(kind),
                  pacer: camelized_param('pacer', kind) == 'true')
  end

  def time_from_start(kind)
    day_and_time = day_and_time(kind)
    day_and_time && (day_and_time - event.start_time - effort.start_offset)
  end

  def day_and_time(kind)
    effort.real_presence && IntendedTimeCalculator.day_and_time(military_time: camelized_param('time', kind),
                                                                effort: effort,
                                                                time_point: time_points[kind],
                                                                lap_splits: effort_lap_splits,
                                                                split_times: ordered_split_times)
  end

  def camelized_param(base, kind)
    params["#{base}_#{kind}".camelize(:lower).to_sym]
  end

  def validate_setup
    warn "DEPRECATION WARNING: params #{params} contain no :lap key; NewLiveEffortData will assume lap: 1 " +
             "but this is deprecated, and lack of a lap parameter may fail in the future." if params[:lap].nil?
  end
end