require 'rails_helper'
include TimeZoneHelpers

RSpec.describe AidStationTimesPresenter do
  subject { AidStationTimesPresenter.new(aid_station, params, current_user) }
  let(:aid_station) { build_stubbed(:aid_station, event: event, split: split) }
  let(:split) { build_stubbed(:split, course: course) }
  let(:event) { build_stubbed(:event, course: course) }
  let(:course) { build_stubbed(:course) }
  let(:params) { ActionController::Parameters.new({}) }
  let(:current_user) { build_stubbed(:admin) }

  let(:live_times) { [live_time_1, live_time_2, live_time_3, live_time_4, live_time_5] }
  let(:live_time_1) { build_stubbed(:live_time, bib_number: '123', absolute_time: time_in_zone(event, '2017-10-31 08:00:00'), source: source_1) }
  let(:live_time_2) { build_stubbed(:live_time, bib_number: '123', absolute_time: time_in_zone(event, '2017-10-31 08:00:15'), source: source_2) }
  let(:live_time_3) { build_stubbed(:live_time, bib_number: '456', absolute_time: time_in_zone(event, '2017-10-31 09:00:00'), source: source_1) }
  let(:live_time_4) { build_stubbed(:live_time, bib_number: '456', absolute_time: time_in_zone(event, '2017-10-31 09:30:00'), source: source_2) }
  let(:live_time_5) { build_stubbed(:live_time, bib_number: '*', absolute_time: time_in_zone(event, '2017-10-31 09:45:45'), source: source_1) }

  let(:source_1) { 'ost-remote-abcd' }
  let(:source_2) { 'ost-remote-wxyz' }

  let(:source_text_1) { 'OSTR (abcd)' }
  let(:source_text_2) { 'OSTR (wxyz)' }

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
      let(:expected_args_1) { {bib_number: '*', effort: nil, live_times: [live_time_5], split_times: [], event: event} }
      let(:expected_args_2) { {bib_number: '123', effort: effort_1, live_times: [live_time_1, live_time_2], split_times: [], event: event} }
      let(:expected_args_3) { {bib_number: '456', effort: effort_2, live_times: [live_time_3, live_time_4], split_times: [], event: event} }

      it 'sends messages to BibSubSplitTimeRow with expected arguments and no split_times' do
        expect(BibSubSplitTimeRow).to receive(:new).with(expected_args_1)
        expect(BibSubSplitTimeRow).to receive(:new).with(expected_args_2)
        expect(BibSubSplitTimeRow).to receive(:new).with(expected_args_3)
        subject.bib_rows
      end
    end

    context 'when related split_times exist' do
      let(:expected_args_1) { {bib_number: '*', effort: nil, live_times: [live_time_5], split_times: [], event: event} }
      let(:expected_args_2) { {bib_number: '123', effort: effort_1, live_times: [live_time_1, live_time_2], split_times: [split_time_1], event: event} }
      let(:expected_args_3) { {bib_number: '456', effort: effort_2, live_times: [live_time_3, live_time_4], split_times: [split_time_2], event: event} }

      let(:grouped_split_times) { [split_time_1, split_time_2].group_by(&:effort_id) }
      let(:split_time_1) { build_stubbed(:split_time, effort: effort_1, lap: 1, split: split, bitkey: 1, time_from_start: live_time_1.absolute_time - event.start_time) }
      let(:split_time_2) { build_stubbed(:split_time, effort: effort_2, lap: 1, split: split, bitkey: 1, time_from_start: live_time_3.absolute_time - event.start_time) }

      before do
        allow(subject).to receive(:grouped_split_times).and_return(grouped_split_times)
      end

      it 'sends messages to BibSubSplitTimeRow with expected arguments and related split_times' do
        expect(BibSubSplitTimeRow).to receive(:new).with(expected_args_1)
        expect(BibSubSplitTimeRow).to receive(:new).with(expected_args_2)
        expect(BibSubSplitTimeRow).to receive(:new).with(expected_args_3)
        subject.bib_rows
      end
    end
  end

  describe '#sources' do
    it 'returns an array of all sources used within live_times' do
      expect(subject.sources).to match_array([source_text_1, source_text_2])
    end
  end
end
