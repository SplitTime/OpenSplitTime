class AidStationLiveTimesPresenter < BasePresenter

  def initialize(aid_station, params, current_user)
    @aid_station = aid_station
    @params = params
    @current_user = current_user
  end

  def bib_rows
    bib_numbers.map { |bib_number| bib_row(bib_number) }
  end
  
  private

  attr_reader :aid_station, :params, :current_user
  delegate :event, :split, to: :aid_station

  def bib_row(bib_number)
    OpenStruct.new(bib_number: bib_number,
                   full_name: indexed_efforts.fetch(bib_number, Effort.null_record).full_name,
                   times: indexed_live_times.fetch(bib_number, []).map { |lt| live_time_attributes(lt) })
  end

  def live_time_attributes(live_time)
    {source: live_time.source,
     military_time: live_time.military_time(time_zone)}
  end

  def time_zone
    event.home_time_zone
  end
  
  def live_times
    @live_times ||= LiveTime.where(event: event, split: split)
  end

  def sources
    @sources ||= live_times.map(&:source).uniq
  end

  def bib_numbers
    @bib_numbers ||= indexed_live_times.keys
  end

  def indexed_efforts
    @indexed_efforts = event.efforts.index_by { |effort| effort.bib_number.to_s }
  end

  def indexed_live_times
    @indexed_live_times ||= live_times.group_by(&:bib_number)
  end
end
