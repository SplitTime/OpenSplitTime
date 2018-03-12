# frozen_string_literal: true

class LiveEffortData
  attr_reader :ordered_splits, :effort, :new_split_times, :indexed_existing_split_times
  delegate :person_id, to: :effort
  ASSUMED_LAP = 1
  SUB_SPLIT_KINDS ||= SubSplit.kinds.map { |kind| kind.downcase.to_sym }
  COMPARISON_KEYS ||= %w(time_from_start pacer stopped_here)

  def self.response_row(args)
    new(args).response_row
  end

  def initialize(args)
    ArgsValidator.validate(params: args,
                           required: [:event, :params],
                           exclusive: [:event, :params, :ordered_splits, :effort, :times_container],
                           class: self.class)
    @event = args[:event]
    @params = args[:params]
    @ordered_splits ||= args[:ordered_splits] || event.ordered_splits
    @effort ||= args[:effort] || effort_from_params
    @times_container = args[:times_container] || SegmentTimesContainer.new(calc_model: :stats)
    @indexed_existing_split_times = ordered_existing_split_times.index_by(&:time_point)
    @new_split_times = {}
    transform_time_data_param
    create_split_times
    assign_stopped_here
    fill_with_null_split_times
  end

  def response_row
    {split_id: subject_split.id,
     effort_id: effort.id,
     event_id: event.id,
     station_index: params[:station_index],
     lap: lap,
     expected_lap: expected_lap,
     split_name: subject_split.base_name,
     split_distance: subject_lap_split.distance_from_start,
     bib_number: effort.bib_number || params[:bib_number],
     effort_name: effort_name,
     dropped_here: stopped_here?,
     live_time_id_in: params[:live_time_id_in],
     live_time_id_out: params[:live_time_id_out],
     time_in: new_split_times[:in].military_time || params[:time_in],
     time_out: new_split_times[:out].military_time || params[:time_out],
     pacer_in: new_split_times[:in].pacer,
     pacer_out: new_split_times[:out].pacer,
     time_in_status: new_split_times[:in].data_status,
     time_out_status: new_split_times[:out].data_status,
     time_in_exists: new_split_times[:in].time_exists,
     time_out_exists: new_split_times[:out].time_exists,
     identical: identical_row_exists?}
        .camelize_keys
  end

  def valid?
    subject_split.real_record? && effort.real_record? && lap.present? && !homeless_booleans?
  end

  def clean?
    proposed_split_times.none? { |st| st.time_exists && st.time_from_start } &&
        proposed_split_times.all?(&:valid_status?)
  end

  def subject_lap_split
    @subject_lap_split ||= LapSplit.new(lap, subject_split)
  end

  def subject_split
    @subject_split ||= ordered_splits.find { |split| split.id == params[:split_id].to_i } || Split.null_record
  end

  def lap
    @lap ||= [[(params[:lap].presence.try(:to_i) || expected_lap || ASSUMED_LAP), 1].max, event.maximum_laps].compact.min
  end

  def expected_lap
    case
    when event.laps_required == 1 then 1
    when subject_split.null_record? || effort.null_record? then nil
    else
      military_time = params[:time_in] || params[:time_out] || ''
      bitkey = (!params[:time_in] && params[:time_out]) ? SubSplit::OUT_BITKEY : SubSplit::IN_BITKEY
      FindExpectedLap.perform(effort: effort, military_time: military_time, split_id: subject_split.id, bitkey: bitkey)
    end
  end

  def split_id
    subject_split.id
  end

  def effort_name
    effort&.full_name.presence || (params[:bib_number].present? ? '[Bib not found]' : 'n/a')
  end

  def stopped_here?
    (params[:dropped_here] == 'true') || (params[:dropped_here] == true)
  end

  def identical_row_exists?
    sub_split_kinds.all? { |kind| identical_split_time_exists?(kind) }
  end

  def identical_split_time_exists?(kind)
    existing_split_time = indexed_existing_split_times[time_points[kind]]
    new_split_time = new_split_times[kind]
    existing_split_time && new_split_time &&
        COMPARISON_KEYS.all? { |key| existing_split_time[key].presence == new_split_time[key].presence }
  end

  def ordered_split_times
    effort_time_points.map { |time_point| indexed_split_times[time_point] }.compact
  end

  def proposed_split_times
    new_split_times.values.select(&:real_record?)
  end

  def ordered_existing_split_times
    @ordered_existing_split_times ||= effort.ordered_split_times.freeze
  end

  def effort_lap_splits
    @effort_lap_splits ||= event.required_lap_splits.presence || (event.lap_splits_through(lap_for_lap_splits))
  end

  def lap_for_lap_splits
    [ordered_existing_split_times.last&.lap || 1, lap].max
  end

  def new_live_times
    @new_live_times ||=
        sub_split_kinds.map do |kind|
          [kind, LiveTime.new(event: event,
                              split: subject_split,
                              bib_number: effort.bib_number,
                              with_pacer: param_with_kind('pacer', kind) == 'true',
                              bitkey: SubSplit.bitkey(kind),
                              source: 'ost-live-entry',
                              entered_time: param_with_kind('time', kind))]
        end.to_h
  end

  private

  attr_reader :event, :params, :times_container

  def homeless_booleans?
    [params[:time_in], params[:time_out]].all?(&:blank?) && new_split_times.values.none?(&:time_exists)
  end

  def effort_from_params
    # ActiveRecord will find bib_number 12 if we use Effort.where(bib_number: '12*')
    return Effort.null_record if params[:bib_number].include?('*')
    event.efforts.find_guaranteed(attributes: {bib_number: params[:bib_number]}, includes: {split_times: :split})
  end

  def indexed_split_times
    @indexed_split_times ||= confirmed_good_split_times.index_by(&:time_point)
  end

  def effort_time_points
    @effort_time_points ||= effort_lap_splits.flat_map(&:time_points)
  end

  # Temporarily change good split_times to confirmed; this optimizes #create_split_times
  # by preventing Interactors::SetEffortStatus from rechecking the status of good times
  def confirmed_good_split_times
    ordered_existing_split_times.dup.each { |st| st.data_status = :confirmed if st.good? }
  end
  
  def transform_time_data_param
    time_data = params[:time_data]&.values
    return unless time_data.present?
    params[:split_id] = time_data.first[:split_id]
    params[:lap] = time_data.first[:lap]
    time_in_data = time_data.find { |row| row[:sub_split_kind] == 'in' }
    time_out_data = time_data.find { |row| row[:sub_split_kind] == 'out' }
    params[:time_in] = time_in_data && time_in_data[:time]
    params[:time_out] = time_out_data && time_out_data[:time]
  end

  def create_split_times
    sub_split_kinds.each do |kind|
      split_time = new_split_time(kind)
      if split_time.time_from_start
        indexed_split_times[split_time.time_point] = split_time
        Interactors::SetEffortStatus.perform(effort, ordered_split_times: ordered_split_times, lap_splits: effort_lap_splits, times_container: times_container)
      end
      self.new_split_times[kind] = split_time
    end
  end

  def assign_stopped_here
    last_new_split_time = sub_split_kinds.map { |kind| new_split_times[kind] }.compact.last
    last_new_split_time.stopped_here = stopped_here? if last_new_split_time
  end

  def fill_with_null_split_times
    SUB_SPLIT_KINDS.each { |kind| self.new_split_times[kind] ||= SplitTime.null_record }
  end

  def sub_split_kinds # Typically [:in] or [:in, :out]
    @sub_split_kinds ||= subject_split.bitkeys.map { |bitkey| SubSplit.kind(bitkey).downcase.to_sym }
  end

  def time_points
    @time_points ||= subject_lap_split.time_points.map { |time_point| [time_point.kind.downcase.to_sym, time_point] }.to_h
  end

  def new_split_time(kind)
    SplitTime.new(effort: effort,
                  time_point: time_points[kind],
                  time_from_start: time_from_start(kind),
                  pacer: (param_with_kind('pacer', kind) == true) || (param_with_kind('pacer', kind) == 'true'),
                  live_time_id: param_with_kind('live_time_id', kind).presence,
                  time_exists: indexed_existing_split_times[time_points[kind]].present?)
  end

  def time_from_start(kind)
    day_and_time = day_and_time(kind)
    day_and_time ? day_and_time - event.start_time_in_home_zone - effort.start_offset : nil
  end

  def day_and_time(kind)
    effort.real_presence && IntendedTimeCalculator.day_and_time(military_time: param_with_kind('time', kind) || '',
                                                                effort: effort,
                                                                time_point: time_points[kind],
                                                                lap_splits: effort_lap_splits,
                                                                split_times: ordered_split_times)
  end

  def param_with_kind(base, kind)
    params["#{base}_#{kind}".to_sym]
  end
end
