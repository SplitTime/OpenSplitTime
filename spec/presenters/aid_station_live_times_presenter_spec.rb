require 'rails_helper'

RSpec.describe AidStationLiveTimesPresenter do
  subject { AidStationLiveTimesPresenter.new(aid_station, params, current_user) }
  let(:aid_station) { build_stubbed(:aid_station, event: event, split: split) }
  let(:split) { build_stubbed(:split, course: course) }
  let(:event) { build_stubbed(:event, course: course) }
  let(:course) { build_stubbed(:course) }
  let(:params) { ActionController::Parameters.new({}) }
  let(:current_user) { build_stubbed(:admin) }

  let(:live_times) { [live_time_1, live_time_2, live_time_3, live_time_4] }
  let(:live_time_1) { build_stubbed(:live_time, bib_number: '123', absolute_time: time_in_zone('2017-10-31 08:00:00'), source: 'ost-remote-abc') }
  let(:live_time_2) { build_stubbed(:live_time, bib_number: '123', absolute_time: time_in_zone('2017-10-31 08:00:15'), source: 'ost-remote-xyz') }
  let(:live_time_3) { build_stubbed(:live_time, bib_number: '456', absolute_time: time_in_zone('2017-10-31 09:00:00'), source: 'ost-remote-abc') }
  let(:live_time_4) { build_stubbed(:live_time, bib_number: '456', absolute_time: time_in_zone('2017-10-31 09:30:00'), source: 'ost-remote-xyz') }
  let(:live_time_4) { build_stubbed(:live_time, bib_number: '*', absolute_time: time_in_zone('2017-10-31 09:45:45'), source: 'ost-remote-abc') }

  let(:effort_1) { build_stubbed(:effort, bib_number: '123') }
  let(:effort_2) { build_stubbed(:effort, bib_number: '456') }
  let(:efforts) { [effort_1, effort_2] }

  before do
    allow(subject).to receive(:live_times).and_return(live_times)
    allow(event).to receive(:efforts).and_return(efforts)
  end

  describe '#sources' do
    it 'returns an array of all sources used within live_times' do
      expect(subject.send(:sources)).to match_array(%w(ost-remote-abc ost-remote-xyz))
    end
  end

  describe '#bib_numbers' do
    it 'returns an array of all bib_numbers used within live_times' do
      expect(subject.send(:bib_numbers)).to match_array(%w(* 123 456))
    end
  end

  describe '#bib_rows' do
    it 'returns an array of objects containing bib number, name, and live_time information' do
      expected = OpenStruct.new(bib_number: '123', full_name: effort_1.full_name, times: [{source: 'ost-remote-abc', military_time: '08:00:00'}, {source: 'ost-remote-xyz', military_time: '08:00:15'}])
      expect(subject.bib_rows.size).to eq(3)
      expect(subject.bib_rows.first).to eq(expected)
    end
  end

  def time_in_zone(time_string)
    ActiveSupport::TimeZone[event.home_time_zone].parse(time_string)
  end
end
