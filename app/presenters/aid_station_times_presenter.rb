class AidStationTimesPresenter < BasePresenter
  delegate :event_name, :split_name, to: :aid_station

  def initialize(aid_station, params, current_user)
    @aid_station = aid_station
    @params = params
    @current_user = current_user
  end

  def bib_rows
    bib_numbers.map { |bib_number| bib_row(bib_number) }
  end

  def sources
    @sources ||= all_live_times.map(&:source).uniq
  end

  private

  attr_reader :aid_station, :params, :current_user
  delegate :event, :split, to: :aid_station

  def bib_row(bib_number)
    OpenStruct.new(bib_number: bib_number,
                   full_name: indexed_efforts.fetch(bib_number, Effort.null_record).full_name,
                   recorded_times: sources.map { |source| [source, find_military_times(bib_number, source).join("\n")] }.to_h,
                   result_times: find_split_times(bib_number).map { |st| [st.lap, st.military_time] }.to_h)
  end

  def find_military_times(bib_number, source)
    # noinspection RubyArgCount
    grouped_live_times.fetch(bib_number, []).select { |lt| lt.source == source }.map { |lt| lt.military_time(time_zone) }
  end

  def find_split_times(bib_number)
    effort = indexed_efforts[bib_number]
    grouped_split_times.fetch(effort&.id, [])
  end

  def time_zone
    event.home_time_zone
  end

  def all_live_times
    LiveTime.where(event: event, split: split)
  end
  
  def live_times
    all_live_times.where(bitkey: bitkey)
  end

  def bib_numbers
    @bib_numbers ||= grouped_live_times.keys.sort_by(&:to_i)
  end

  def indexed_efforts
    @indexed_efforts = event.efforts.index_by { |effort| effort.bib_number.to_s }
  end

  def grouped_split_times
    @indexed_split_times ||= event.split_times.includes(effort: :event).where(split: split, bitkey: bitkey).group_by(&:effort_id)
  end

  def grouped_live_times
    @indexed_live_times ||= live_times.group_by(&:bib_number)
  end

  def sub_split_kind
    params[:sub_split_kind] || 'in'
  end

  def bitkey
    SubSplit.bitkey(sub_split_kind)
  end
end
