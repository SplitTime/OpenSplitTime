require 'rails_helper'

RSpec.describe AidStationTimesPresenter do
  subject { AidStationTimesPresenter.new(aid_station, params, current_user) }
  let(:aid_station) { build_stubbed(:aid_station, event: event, split: split) }
  let(:split) { build_stubbed(:split, course: course) }
  let(:event) { build_stubbed(:event, course: course) }
  let(:course) { build_stubbed(:course) }
  let(:params) { ActionController::Parameters.new({}) }
  let(:current_user) { build_stubbed(:admin) }

  let(:live_times) { [live_time_1, live_time_2, live_time_3, live_time_4, live_time_5] }
  let(:live_time_1) { build_stubbed(:live_time, bib_number: '123', absolute_time: time_in_zone('2017-10-31 08:00:00'), source: 'ost-remote-abc') }
  let(:live_time_2) { build_stubbed(:live_time, bib_number: '123', absolute_time: time_in_zone('2017-10-31 08:00:15'), source: 'ost-remote-xyz') }
  let(:live_time_3) { build_stubbed(:live_time, bib_number: '456', absolute_time: time_in_zone('2017-10-31 09:00:00'), source: 'ost-remote-abc') }
  let(:live_time_4) { build_stubbed(:live_time, bib_number: '456', absolute_time: time_in_zone('2017-10-31 09:30:00'), source: 'ost-remote-xyz') }
  let(:live_time_5) { build_stubbed(:live_time, bib_number: '*', absolute_time: time_in_zone('2017-10-31 09:45:45'), source: 'ost-remote-abc') }

  let(:effort_1) { build_stubbed(:effort, bib_number: '123') }
  let(:effort_2) { build_stubbed(:effort, bib_number: '456') }
  let(:efforts) { [effort_1, effort_2] }

  before do
    allow(subject).to receive(:all_live_times).and_return(live_times)
    allow(subject).to receive(:live_times).and_return(live_times)
    allow(event).to receive(:efforts).and_return(efforts)
  end

  describe '#bib_rows' do
    context 'when no related split_times exist' do
      let(:expected_1) { OpenStruct.new(bib_number: '*', full_name: '', recorded_times: {'ost-remote-abc' => '09:45:45', 'ost-remote-xyz' => ''}, result_times: {}) }
      let(:expected_2) { OpenStruct.new(bib_number: '123', full_name: effort_1.full_name, recorded_times: {'ost-remote-abc' => '08:00:00', 'ost-remote-xyz' => '08:00:15'}, result_times: {}) }
      let(:expected_3) { OpenStruct.new(bib_number: '456', full_name: effort_2.full_name, recorded_times: {'ost-remote-abc' => '09:00:00', 'ost-remote-xyz' => '09:30:00'}, result_times: {}) }

      it 'returns an array of objects containing bib number, name, and live_time information' do
        expect(subject.bib_rows.size).to eq(3)
        expect(subject.bib_rows).to match_array([expected_1, expected_2, expected_3])
      end
    end

    context 'when related split_times exist' do
      let(:expected_1) { OpenStruct.new(bib_number: '*', full_name: '', recorded_times: {'ost-remote-abc' => '09:45:45', 'ost-remote-xyz' => ''}, result_times: {}) }
      let(:expected_2) { OpenStruct.new(bib_number: '123', full_name: effort_1.full_name, recorded_times: {'ost-remote-abc' => '08:00:00', 'ost-remote-xyz' => '08:00:15'}, result_times: {1 => split_time_1.military_time}) }
      let(:expected_3) { OpenStruct.new(bib_number: '456', full_name: effort_2.full_name, recorded_times: {'ost-remote-abc' => '09:00:00', 'ost-remote-xyz' => '09:30:00'}, result_times: {1 => split_time_2.military_time}) }

      let(:grouped_split_times) { [split_time_1, split_time_2].group_by(&:effort_id) }
      let(:split_time_1) { build_stubbed(:split_time, effort: effort_1, lap: 1, split: split, bitkey: 1, time_from_start: live_time_1.absolute_time - event.start_time) }
      let(:split_time_2) { build_stubbed(:split_time, effort: effort_2, lap: 1, split: split, bitkey: 1, time_from_start: live_time_3.absolute_time - event.start_time) }

      before do
        allow(subject).to receive(:grouped_split_times).and_return(grouped_split_times)
      end

      it 'returns an array of objects containing bib number, name, and live_time information' do
        expect(subject.bib_rows.size).to eq(3)
        expect(subject.bib_rows).to match_array([expected_1, expected_2, expected_3])
      end
    end
  end

  describe '#sources' do
    it 'returns an array of all sources used within live_times' do
      expect(subject.sources).to match_array(%w(ost-remote-abc ost-remote-xyz))
    end
  end

  def time_in_zone(time_string)
    ActiveSupport::TimeZone[event.home_time_zone].parse(time_string)
  end
end
